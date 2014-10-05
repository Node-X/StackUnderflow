require 'rails_helper'

RSpec.describe Tag, :type => :model do

  describe "associations" do
    it { is_expected.to have_and_belong_to_many :questions }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :name  }
    it { is_expected.to ensure_length_of(:name).is_at_least(1).is_at_most(24)  }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive  }
    it { is_expected.to allow_value("tag", "TAG", "C++", "some_tag", "some-tag", "a123", "android-4.2").for :name  }
    it { is_expected.not_to allow_value("t a g", "123", "123a", "a123").for :name  }
  end

end
