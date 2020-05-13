class ErrorsController < WebsiteController

  def internal_server_error
    respond_to do |format|
      format.html do
        render 'error', status: 500, content_type: 'text/html',
               locals: { status_code: 500,
                         status_message: 'Internal Server Error',
                         message: 'Something went wrong.' }
      end
    end
  end

  def not_found
    respond_to do |format|
      format.html do
        render 'error', status: 404, content_type: 'text/html',
               locals: { status_code: 404,
                         status_message: 'Not Found',
                         message: 'There is no resource available at this URL.' }
      end
    end
  end

end
