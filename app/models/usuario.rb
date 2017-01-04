class Usuario < ActiveRecord::Base
    require 'securerandom'
    attr_accessor :password
    before_create :confirmation_token
    EMAIL_REGEX = /\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    validates :username, :presence => true, :uniqueness => true, :length => { :in => 3..20 }
    validates :email, :presence => true, :uniqueness => true, :format => EMAIL_REGEX
    validates :password, :confirmation => true #password_confirmation attr
    validates_length_of :password, :in => 6..20, :on => :create
    def generate_token
        self.confirm_token = SecureRandom.urlsafe_base64.to_s
        self.save
    end
    def self.authenticate(username_or_email="", login_password="")
        if  EMAIL_REGEX.match(username_or_email)    
            user = Usuario.find_by_email(username_or_email)
        else
            user = Usuario.find_by_username(username_or_email)
        end
        if user && user.match_password(login_password)
            return user
        else
            return false
        end
    end
    def email_activate
        self.email_confirmed = true
        self.confirm_token = nil
        save!(:validate => false)
    end   
    def match_password(login_password="")
        encrypted_password == Digest::SHA1.hexdigest(login_password)
    end
    private
    def confirmation_token
      if self.confirm_token.blank?
          self.confirm_token = SecureRandom.urlsafe_base64.to_s
      end
    end
end
