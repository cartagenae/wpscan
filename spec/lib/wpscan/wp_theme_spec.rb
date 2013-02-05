# encoding: UTF-8
#--
# WPScan - WordPress Security Scanner
# Copyright (C) 2012-2013
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require File.expand_path(File.dirname(__FILE__) + '/wpscan_helper')

describe WpTheme do
  before :all do
    @target_uri = URI.parse('http://example.localhost/')

    Browser.instance(
      config_file:   SPEC_FIXTURES_CONF_DIR + '/browser/browser.conf.json',
      cache_timeout: 0
    )
  end

  describe '#initialize' do
    it 'should not raise an exception' do
      expect { WpTheme.new(base_url: 'url', path: 'path', wp_content_dir: 'dir', name: 'name') }.to_not raise_error
    end

    it 'should not raise an exception (wp_content_dir not set)' do
      expect { WpTheme.new(base_url: 'url', path: 'path', name: 'name') }.to_not raise_error
    end

    it 'should raise an exception (base_url not set)' do
      expect { WpTheme.new(path: 'path', wp_content_dir: 'dir', name: 'name') }.to raise_error
    end

    it 'should raise an exception (path not set)' do
      expect { WpTheme.new(base_url: 'url', wp_content_dir: 'dir', name: 'name') }.to raise_error
    end

    it 'should raise an exception (name not set)' do
      expect { WpTheme.new(base_url: 'url', path: 'path', wp_content_dir: 'dir') }.to raise_error
    end
  end

  describe '#find_from_css_link' do
    let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_WP_THEME_DIR + '/find/css_link' }

    after :each do
      if @expected_name
        stub_request_to_fixture(url: @target_uri.to_s, fixture: @fixture)

        wp_theme = WpTheme.find_from_css_link(@target_uri)
        wp_theme.should be_a WpTheme
        wp_theme.name.should === @expected_name
      end
    end

    it 'should return nil if no theme is present' do
      stub_request(:get, @target_uri.to_s).to_return(status: 200, body: '')

      WpTheme.find_from_css_link(@target_uri).should be_nil
    end

    it 'should return a WpTheme object with .name = twentyeleven' do
      @fixture = fixtures_dir + '/wordpress-twentyeleven.htm'
      @expected_name = 'twentyeleven'
    end

    # http://code.google.com/p/wpscan/issues/detail?id=131
    # Theme name with spaces raises bad URI(is not URI?)
    it 'should not raise an error if the theme name has spaces or special chars' do
      @fixture = fixtures_dir + '/theme-name-with-spaces.html'
      @expected_name = 'Copia di simplefolio'
    end

    # https://github.com/wpscanteam/wpscan/issues/18
    it 'should get the theme if the <link> is inline with some other tags' do
      @fixture = fixtures_dir + '/inline_link_tag.html'
      @expected_name = 'inline'
    end

    it 'should get the theme name even if relative URLs are used' do
      @fixture = fixtures_dir + '/relative_urls.html'
      @expected_name = 'theme_name'
    end
  end

  describe '#find_from_wooframework' do
    let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_WP_THEME_DIR + '/find/wooframework' }

    after :each do
      stub_request_to_fixture(url: @target_uri.to_s, fixture: @fixture)

      wp_theme = WpTheme.find_from_wooframework(@target_uri)

      stub_request(:get, wp_theme.default_style_url.to_s).to_return(status: 200)
      stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 200)

      wp_theme.should be_a WpTheme unless wp_theme.nil?
      wp_theme.should === @expected_theme
    end

    it "should return a WpTheme object with .name 'Editorial' and .version '1.3.5'" do
      @fixture = fixtures_dir + '/editorial-1.3.5.html'
      @expected_theme = WpTheme.new(name: 'Editorial', version: '1.3.5', base_url: 'http://example.localhost/', path: 'Editorial')
    end

    it "should return a WpTheme object with .name 'Merchant'" do
      @fixture = fixtures_dir + '/merchant-no-version.html'
      @expected_theme = WpTheme.new(name: 'Merchant', base_url: 'http://example.localhost/', path: 'Merchant')
    end
  end

  describe '#find' do
    let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_WP_THEME_DIR + '/find' }

    after :each do
      stub_request_to_fixture(url: @target_uri.to_s, fixture: @fixture)

      wp_theme = WpTheme.find(@target_uri)

      if @expected_name
        wp_theme.should be_a WpTheme
        wp_theme.name.should === @expected_name
      else
        wp_theme.should be_nil
      end
    end

    it 'should return nil if no theme is found' do
      @fixture = SPEC_FIXTURES_DIR + '/empty-file'
      @expected_name = nil
    end

    it "should return a WpTheme object with .name 'twentyeleven'" do
      @fixture = fixtures_dir + '/css_link/wordpress-twentyeleven.htm'
      @expected_name = 'twentyeleven'
    end

    it "should a WpTheme object with .name 'Merchant'" do
      @fixture = fixtures_dir + '/wooframework/merchant-no-version.html'
      @expected_name = 'Merchant'
    end
  end

  describe '#version' do
    let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_WP_THEME_DIR + '/version' }
    let(:theme_style_url) { @target_uri.merge('wp-content/themes/spec-theme/style.css').to_s }

    after :each do
      if @fixture
        stub_request_to_fixture(url: theme_style_url, fixture: @fixture)

        wp_theme = WpTheme.new(name: 'spec-theme', style_url: theme_style_url, base_url: 'http://example.localhost/', path: 'spec-theme')

        stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 200)

        wp_theme.version.should === @expected
      end
    end

    it 'should return nil if the version is not found' do
      @fixture = fixtures_dir + '/twentyeleven-unknow.css'
      @expected = nil
    end

    it 'should return nil if the style_url is nil' do
      wp_theme = WpTheme.new(name: 'hello-world', base_url: 'http://example.localhost/', path: 'hello-world')
      stub_request(:get, wp_theme.default_style_url.to_s).to_return(status: 200)
      stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 200)
      wp_theme.version.should be_nil
    end

    it 'should return 1.3' do
      @fixture = fixtures_dir + '/twentyeleven-1.3.css'
      @expected = '1.3'
    end

    it 'should return 1.5.1' do
      @fixture = fixtures_dir + '/bueno-1.5.1.css'
      @expected = '1.5.1'
    end

    it 'should get the version from default style.css url' do
      wp_theme = WpTheme.new(name: 'hello-world', base_url: 'http://example.localhost/', path: 'hello-world')
      stub_request(:get, wp_theme.default_style_url.to_s).to_return(status: 200, body: 'Version: 1.3.4.5')
      stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 404)
      wp_theme.version.should === '1.3.4.5'
    end

    it 'should get the version from custom style.css url' do
      style_url = 'http://example.localhost/custom_style.css'
      wp_theme = WpTheme.new(name: 'hello-world', base_url: 'http://example.localhost/', path: 'hello-world', style_url: style_url)
      stub_request(:get, style_url).to_return(status: 200, body: 'Version: 1.3.4.5')
      stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 404)
      wp_theme.version.should === '1.3.4.5'
    end

    it 'should get the version from readme.txt' do
      wp_theme = WpTheme.new(name: 'hello-world', base_url: 'http://example.localhost/', path: 'hello-world')
      stub_request(:get, wp_theme.default_style_url.to_s).to_return(status: 404)
      stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 200, body: 'Stable Tag: 1.2.3.4')
      wp_theme.version.should === '1.2.3.4'
    end

    it 'should get the version from readme.txt' do
      wp_theme = WpTheme.new(name: 'hello-world', base_url: 'http://example.localhost/', path: 'hello-world')
      stub_request(:get, wp_theme.default_style_url.to_s).to_return(status: 200)
      stub_request(:get, wp_theme.readme_url.to_s).to_return(status: 200, body: 'Stable Tag: 1.2.3.4')
      wp_theme.version.should === '1.2.3.4'
    end
  end

  describe '#===' do
    it 'should return false (name not equal)' do
      instance = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/name/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '1.0'
      )
      instance2 = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/newname/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '1.0'
      )
      (instance === instance2).should == false
    end

    it 'should return false (version not equal)' do
      instance = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/name/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '1.0'
      )
      instance2 = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/name/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '2.0'
      )
      (instance === instance2).should == false
    end

    it 'should return false (version and name not equal)' do
      instance = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/name/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '1.0'
      )
      instance2 = WpTheme.new(
        base_url: 'http://sub.example.com/path/to/wordpress/',
        path: 'themes/newname/asdf.php',
        vulns_file: 'XXX.xml',
        version: '2.0'
      )
      (instance === instance2).should == false
    end

    it 'should return true' do
      instance = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/test/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '1.0'
      )
      instance2 = WpTheme.new(
        base_url:   'http://sub.example.com/path/to/wordpress/',
        path:       'themes/test/asdf.php',
        vulns_file: 'XXX.xml',
        version:    '1.0'
      )
      (instance === instance2).should == true
    end
  end
end
