require 'test_helper'

class DownloadPolicyTest < ActiveSupport::TestCase

  setup do
    @download = downloads(:one)
    @context  = RequestContext.new(client_ip:       "127.0.0.1",
                                   client_hostname: "localhost")
  end

  # file?()

  test "file?() does not authorize a client IP different from that of the
  Download" do
    @context.client_ip       = "1.1.1.1"
    @context.client_hostname = "example.org"
    assert !DownloadPolicy.new(@context, @download).file?
  end

  test "file?() authorizes a client IP matching that of the Download" do
    assert DownloadPolicy.new(@context, @download).file?
  end

  # show?()

  test "show?() does not authorize a client IP different from that of the
  Download" do
    @context.client_ip       = "1.1.1.1"
    @context.client_hostname = "example.org"
    assert !DownloadPolicy.new(@context, @download).show?
  end

  test "show?() authorizes a client IP matching that of the Download" do
    assert DownloadPolicy.new(@context, @download).show?
  end

end
