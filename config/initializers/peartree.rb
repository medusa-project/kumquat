PearTree::Application.peartree_config =
    YAML.load_file(File.join(Rails.root, 'config', 'peartree.yml'))[Rails.env]