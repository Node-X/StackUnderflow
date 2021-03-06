class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :auth_provider

  def facebook
  end

  def twitter
  end

  def vkontakte
  end

  def github
  end

  private
    
    def auth_provider
      auth = request.env['omniauth.auth']
      if user_signed_in?
        current_user.identities.create(provider: auth.provider, uid: auth.uid)
        redirect_to logins_user_path(current_user)
      else
        @user = User.find_for_oauth(auth)
        sign_in_and_redirect @user, event: :authentication
        set_flash_message :notice, :success, kind: params[:action].capitalize if is_navigational_format?
      end
    end
end
