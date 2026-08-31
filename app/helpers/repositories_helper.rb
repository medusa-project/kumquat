module RepositoriesHelper
  REPOSITORY_BANNERS = {
    78 => 'aces-header.jpg',
    23 => 'rbml-header.jpg',
    22 => 'UniversityArchives.jpg',
    25 => 'hpnl-header.jpg',
    27 => 'ALA-Archives-header.jpg',
    54 => 'cropped-ihx_header.jpg',
    73 => 'mathematicslibrary-header.jpg'
}.freeze 

DEFAULT_BANNER = 'cropped-ihx_header.jpg'

  def repository_banner(repository)
    REPOSITORY_BANNERS.fetch(repository.id, DEFAULT_BANNER)
  end
end