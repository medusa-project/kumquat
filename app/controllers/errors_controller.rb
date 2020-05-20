class ErrorsController < WebsiteController

  def not_found
    respond_to do |format|
      format.html do
        render 'error', status: 404, content_type: 'text/html',
               locals: { status_code: 404,
                         status_message: 'Not Found',
                         message: 'There is no resource available at this URL.' }
      end
      format.all do
        render plain: '404 Not Found', content_type: 'text/plain',
               status: :not_found
      end
    end
  end

end
