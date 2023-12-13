# frozen_string_literal: true

class DownloadPolicy < ApplicationPolicy

  def initialize(request_context, download)
    @request_context = request_context
    @download        = download
  end

  def file?
    show?
  end

  def show?
    @download.ip_address == @request_context.client_ip
  end

end
