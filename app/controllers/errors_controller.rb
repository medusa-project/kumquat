class ErrorsController < WebsiteController

  def internal_server_error
    render 'error', status: 500,
           locals: { status_code: 500,
                     status_message: 'Internal Server Error',
                     message: 'Something went wrong.' }
  end

  def not_found
    render 'error', status: 404,
           locals: { status_code: 404,
                     status_message: 'Not Found',
                     message: 'There is no resource available at this URL.' }
  end

end
