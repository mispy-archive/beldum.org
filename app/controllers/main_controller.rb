class MainController < ApplicationController
  def test
    render :layout => false
    @remote_ip = request.remote_addr
    #render :json => [{"_id" => "4d925dbe4aa6936d4f0cdefe","name" => "Devon","state_id" => 1},{"_id" => "4d925dbe4aa6936d4f0cdeff","name" => "Berwickshire","state_id" => 2}]
  end
end
