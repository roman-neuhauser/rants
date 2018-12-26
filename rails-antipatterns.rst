.. vim: ft=rst sts=2 sw=2 tw=72
.. default-role:: literal

########################################################################
      Rails Antipatterns: Best Practice Ruby On Rails Refactoring
########################################################################
========================================================================
                                a review
========================================================================

:Author: Roman Neuhauser
:Contact: rneuhauser@suse.cz
:Copyright: This document is in the public domain.

.. contents:: :depth: 1

The object of this mildly polemic review is a book called
*Rails Antipatterns: Best Practice Ruby On Rails Refactoring*,
by Chad Pytel from **thoughtbot** and Tammer Saleh from **Engine Yard**.

My expectations may have been high, but not unfairly so: the book title
certainly sounds authoritative, and the companies the authors hail from
have quite some reputation in the Rails community.
So I was looking forward to clarity and/or insight on par with Beck's,
Fowler's, Johnson's, or Holub's publications.
The book has come short of my expectations, by a large margin.

First, I see a few problems with the presentation.
Compared to GoF's Design Patterns or Fowler's Refactoring, this book
lacks structure.
An (alleged) antipattern is presented, and off we go to (alleged) code
improvements.

I cannot really complain about clarity as the book gives clearly wrong
advice in many places.
Insight is a different topic, and the book is lacking in this regard.
The *antipatterns* discussed in this book are often beside the boat,
solutions offered are questionable, and there's next to no discussion
of inherent downsides.

I didn't finish the book, the parts I read are critiqued in this text.

Voyeuristic Models / Law of Demeter
====================================

:page: 2

The bad code
************

::

  class Address < ActiveRecord::Base
    belongs_to :customer
  end

  class Invoice < ActiveRecord::Base
    belongs_to :customer
  end

  class Customer < ActiveRecord::Base
    has_one :address
    has_many :invoices
  end

  <%= @invoice.customer.name %>
  <%= @invoice.customer.address.street %>
  <%= @invoice.customer.address.city %>
  <%= @invoice.customer.address.state %>
  <%= @invoice.customer.address.zip_code %>

Suggested improvement no. 1
***************************

::

  class Customer < ActiveRecord::Base
    has_one :address
    has_many :invoices
    def street
      address.street
    end
    def city
      address.city
    end
    def zip_code
      address.zip_code
    end
  end

  class Invoice < ActiveRecord::Base
    belongs_to :customer

    def customer_name
      customer.name
    end
    def customer_street
      customer.street
    end
    def customer_city
      customer.city
    end
    def customer_zip_code
      customer.zip_code
    end
  end

  <%= @invoice.customer_name %>
  <%= @invoice.customer_street %>
  <%= @invoice.customer_city %>
  <%= @invoice.customer_zip_code %>

Suggested improvement no. 2
***************************

::

  class Customer < ActiveRecord::Base
    has_one :address
    has_many :invoices

    delegate :name, :street, :city,
      :to => :address
  end

  class Invoice < ActiveRecord::Base
    belongs_to :customer

    delegate :name, :street, :city,
      :to => :customer, :prefix => true
  end

  <%= @invoice.customer_name %>
  <%= @invoice.customer_street %>
  <%= @invoice.customer_city %>
  <%= @invoice.customer_zip_code %>


The misnomer aside (discussed models are not Voyeuristic, they're
Exhibitionist or Promiscuous), there's a fundamental problem with
the presented "solution": it's not a solution, it's a lawyerism.
It's following the letter, but not the spirit of the "law" in question.

Sure, wrapper methods give the programmer a certain level of flexibility
in how the returned data is gathered, and `delegate` provides a concise
default implementation, but the real problem is elsewhere: in the client
code.

Instances of most `Address`-like classes in a program are used in
multiple places.
I may feel like I've won big time thanks to Rails' concise
implementation tools, but the real weigth is in the uses.

Let's say we started with the above code.
Our application has grown, and there are many places in the code
accessing customer address, both in views and models.

Now we need to add `invoice.customer_phone`.
No matter how it's spelled (underscore or dot), we have quite a task
before us to update all places where the address is manipulated.

Real solution?  Tell, Don't Ask!
********************************

We put code into functions, objects and methods for understandability
(through naming, and scope, lifetime and visibility management) and
reusability (invoking the same code in multiple places).
Most functions or methods have more than one call site.
It follows that most of maintenance effort for a function or method goes
into code which uses it, not its implementation.

The biggest problem is not even code, it's data.
The classes presented in the example have no *code*, they're data
clumps.
The more you use objects of the `Address` class, the more places will
require review and modification, should `Address` gain or lose a line
(say `country`).
The more data travels across a program, the worse the problem gets.

Recognition of this problem is one of the bases of OOP: objects put
together data and code which acts on that data precisely to limit the
data flow in the program.

::

  class Invoice
    def paint_on display
      customer.paint_on display
      ...
    end
  end

  class Customer
    def paint_on display
      address.paint_on display
      ...
    end
  end

  class Address
    def paint_on display
      display.block self.class.name do
        [:name, :street, :city, :zip_code].each do |m|
          display.line :key => m, :val => instance_variable_get m
        end
      end
    end
  end

  class Display
    def initialize fd
      @fd = fd
    end
    def write str
      @fd.write str
    end
    # def line args; end
  end

  class MultilineDisplay < Display
    def block label, &block
      write "#{label}:\n"
      yield
    end
    def line args
      write "  %{key}: %{val}\n" % args
    end
  end

  class SinglelineDisplay < Display
    def block label, &block
      write "#{label}:"
      yield
      write "\n"
    end
    def line args
      fd.write " %{key}=%{val}" % args
    end
  end

Fat Models
==========

:page: 14

Bad code
********

::

  class Order < ActiveRecord::Base
    def self.find_this...
    def self.find_that...

    def to_xml...
    def to_json...
  end

Bad advice
**********

SRP
~~~

The authors mention Single Responsibility Principle (SRP) right after giving
an advice that goes straight against it:

  An `Order` object should be responsible for order-like processes:
  calculating price, managing line items, and so on.

This is true in general, but not in Railsland, where `Order` derives
from `ActiveRecord::Base`; these classes have the single responsibility
of handling the persistence!  At least, that's how it should be.

Tight coupling
~~~~~~~~~~~~~~

Another piece of bad advice given by the authors (p. 17) is to hardcode
a collaborator class into the `Order` class.

::

  class Order < ActiveRecord::Base
    def converter
      OrderConverter.new self
    end
  end

  class OrderConverter
    attr_reader :order
    def initialize order
      @order = order
    end

    def to_xml...
    def to_json...
  end

Of course, `order.converter.to_xml` has one dot too many, so let's add
delegates to `Order`...

Crying All the Way to the Bank
******************************

This is sold as part of the "better" code, lifted from the Rails
documentation(!): ::

  class Money
    include Comparable
    attr_accessor :amount_in_cents, :currency

    def initialize amount_in_cents, currency
      @amount_in_cents = amount_in_cents
      @currency = currency
    end

    def in_currency other_currency
      # currency exchange logic
    end

    def amount
      amount_in_cents / 100
    end

    def <=> other_money
      amount_in_cents <=>
        other_money.in_currency(currency).amount_in_cents
    end
  end

Crying yet?  You should be, as I intend to take your hard earned Euros
and turn them into Greek Drachmas: ::

  your_euros = Money.new 10**6, :euro
  your_euros.currency = :drachma

On the elemetary level, this is a nice example in support of the claim
that getters and setters are evil.  
On the best practice level, mutable instances representing immutable
values are a nogo.

Note: when I saw the `in_currency` method I hoped currencies would be
objects that have access to an *exchange*, an object which knows current
rates.
Alas, no cookie, they're just symbols, and `in_currency` needs to have
knowledge of all exchange rates.
This means `Money` needs static access to an exchange.  Ouch...

Authorization Astronaut
=======================

:page: 74

This whole section is set up around a strawman, and the suggested
solution has more downsides than upsides.

The authors set off with ::

  class User < ActiveRecord::Base
    def has_role?(role_in_question)
      self.roles.first(
        :conditions => [:name => role_in_question]
      ) ? true : false
    end
    def has_roles?(roles_in_question)
      self.roles.all(
        :conditions => ["name in (?)", roles_in_question]
      ).length > 0
    end
    def can_post?
      self.has_roles?(['admin', 'editor', 'writer'])
    end
    def can_review_posts?
      self.has_roles?(['admin', 'editor'])
    end
    def can_edit_content?
      self.has_roles?(['admin', 'editor'])
    end
    def can_edit_post?(post)
      self == post.user || self.has_roles?(['admin', 'editor'])
    end
  end

of which the authors say

  There are a number of issues with this code.
  The `has_role?` method isn't used; only the `has_roles?` method is
  used, and not just in the `User` model but in the rest of the
  application as well.
  This method was written in anticipation of being used.

  Providing these `can_*` convenience methods is a slippery slope.
  At the very least there is a question about when to provide these
  methods, and there is a vague and inconsistent interface.
  At the worst, these methods are actually written ahead of any need,
  based on speculation about what authorization checks may be needed in
  the future of the application.

  Finally, the `User` model is hardcoding all the strings used to
  identify the individual roles.
  If one or more of these were to change, you would need to change them
  throughout the application.

Simplify with Simple Flags
**************************

The first suggested solution is to shun `Role` completely and rely
on boolean attributes in `User`:

::

  class User < ActiveRecord::Base
  end

The authors have this to say:

  With this sweeping change, you can get rid of the `Role` model
  completely.
  You have given the `User` model admin, editor, and writer Booleans.
  With these Booleans, Active Record gives you nice `admin?`, `editor?`,
  and `writer?` query methods.
  In the future, it may be necessary to add additional authorization
  roles to the application.
  If you need to add just one or two roles, it's not unreasonable to add
  the additional Booleans to the `User` model.

::

  class User < ActiveRecord::Base
    has_many :roles
  end

  class Role < ActiveRecord::Base
    TYPES = [...]

    validates :name, :inclusion => { :in => TYPES }

    class << self
      TYPES.each do |role_type|
        define_method "#{role_type}?" do
          exists?(:name => role_type)
        end
      end
    end
  end

The rationale:

  To facilitate the change from individual Booleans to a `Role` model,
  you use `define_method` to provide a query method for each role type
  that allows you to call `user.roles.admin?`.
  It is also possible to put these defined methods right on the `User`
  model itself, so that `user.admin?` can be called.

  One of the arguments for the former method is that it keeps all the
  `Role`-related code encapsulated in the `Role` model.
  While this is a legitimate point, putting the query method for roles
  isn't a particularly egregious violation, especially considering the
  fact that the roles and the methods for asking about them were
  previously directly on the `User` model.

Problems with the Problem and Suggested Solution
************************************************

The basic problem with this chapter is the fact that it attacks a
strawman the authors erected themselves.
The opening code is bad because the (imaginary) application it's part
of does not use it, but that does not stop the authors from ripping
it apart as if it was bad full stop.

  Providing these `can_*` convenience methods is a slippery slope.
  At the very least there is a question about when to provide these
  methods, and there is a vague and inconsistent interface.

I'm curious about the slippery slope.
Where does it lead?
What are the downsides?
What are the tradeoffs compared to the suggested solution?
These are not rhetorical questions, as the api championed by the authors
is IMO worse than the "bad" one.

  Finally, the `User` model is hardcoding all the strings used to
  identify the individual roles.
  If one or more of these were to change, you would need to change them
  throughout the application.

Ooookaaay, and the suggested query methods are an improvement over that
how exactly?
If ::

  user.has_role? 'admin'

presents a problem for refactorings, then ::

  user.admin?

is no improvement.  In both cases, if you change the name of the role,
you need to rummage through your program to change all occurrences,
or set up a mapping in the `User` or `Role` class.

So, what is the actual problem with `User#has_role?`?
Unless the application's task is role management, this method does not
answer a question from the application's domain.
Client code is really interested in user's capabilities, which means
`User#can_edit_article?` is a better abstraction.
Ok, but what does that mean in practice?
Business rules evolve, and by the time the client approaches you with
a request to change who can edit articles, you'll have a few hundred
places in the application like this: ::

  if user.admin? || user.editor? || article.author == user
    ...
  end

"But we need to have a senior editor role as well!"

Real solution?  Tell, Don't Ask!
********************************

::

  class User
    def edit article
      raise WriteAccess.new article unless can_edit_article? article
      ...
    end
  end

  user.edit article

