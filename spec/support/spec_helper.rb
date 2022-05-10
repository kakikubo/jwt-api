# frozen_string_literal: true

# https://breakthrough-tech.yuta-u.com/rspec/how-to-make-spec-support/
module SpecHelpers
  def active_user
    User.find_by(activated: true)
  end
end
