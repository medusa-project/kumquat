##
# Rack application to handle streaming zip downloads.
#
# For the most part, this the same URL query parameters as
# ItemsController.index() are accepted, but cross-collection requests (i.e.
# requests without a collection_id parameter) are not accepted due to the
# huge amount of content they could retrieve. (But, perhaps it would be better
# to limit the total number of items instead.)
#
class ItemsZipDownloader < AbstractZipDownloader

  def call(env)
    super(env)
    params = Rack::Utils.parse_nested_query(env['QUERY_STRING']).symbolize_keys

    if params[:collection_id].blank? and params[Item::SolrFields::PARENT_ITEM.to_sym].blank?
      return [400, {}, 'To spare computing resources, zip file '\
        'generation across collection contexts is disabled.']
    end

    finder = ItemFinder.new.
        client_hostname(env['HTTP_HOST'].split(':').first).
        client_ip(env['REMOTE_ADDR']).
        #client_user(current_user). TODO: fix
        collection_id(params[:collection_id]).
        query(params[:q]).
        filter_queries(params[:fq]).
        include_children(true).
        sort(Item::SolrFields::ID).
        start(params[:start]).
        limit(BATCH_SIZE)

    Rails.logger.info("ZipDownloader-#{instance_id}: "\
            "processing request for: #{finder.to_s.split("\n").join('; ')}")

    send_items(finder.to_a)
  end

end
