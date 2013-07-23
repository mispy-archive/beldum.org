class TestModel < ActiveRecord::Base
  before_destroy :do_stuff

  scope :stuff, order("id DESC NULLS LAST")

  def do_stuff
    false
  end
end
