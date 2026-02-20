rockspec_format = '3.0'
package = 'blink-cmp-ghostty'
version = 'scm-1'

source = {
  url = 'git+https://github.com/barrettruth/blink-cmp-ghostty.git',
}

description = {
  summary = 'Ghostty configuration completion source for blink.cmp',
  homepage = 'https://github.com/barrettruth/blink-cmp-ghostty',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1',
}

test_dependencies = {
  'nlua',
  'busted >= 2.1.1',
}

test = {
  type = 'busted',
}

build = {
  type = 'builtin',
}
