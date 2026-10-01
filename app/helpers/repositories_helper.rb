module RepositoriesHelper
  REPOSITORY_BANNERS = {
    22 => 'UniversityArchives.jpg',
    23 => 'rbml-header.jpg',
    25 => 'hpnl-header.jpg',
    27 => 'ALA-Archives-header.jpg',
    31 => 'Sousa_banner_header.jpg',
    44 => 'cropped-bug-mold-and-water-damage_crop.jpg',
    54 => 'cropped-ihx_header.jpg',
    73 => 'mathematicslibrary-header.jpg'
    78 => 'aces-header.jpg',
    # 72 => University Library
    # 24 => Champaign County Historical Archives
    # 28 => Medusa Admin
    # 32 => Map Library
    # 45 => Ricker Library
}.freeze 

DEFAULT_BANNER = 'cropped-ihx_header.jpg'

  def repository_banner(repository)
    REPOSITORY_BANNERS.fetch(repository.id, DEFAULT_BANNER)
  end
end