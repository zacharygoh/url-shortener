require 'rails_helper'

RSpec.feature 'URL Shortening', type: :feature, js: true do
  scenario 'User shortens a URL successfully' do
    stub_request(:get, 'https://www.coingecko.com/en/coins/bitcoin')
      .to_return(body: '<html><head><title>Bitcoin</title></head></html>')
    visit root_path

    expect(page).to have_content('CoinGecko URL Shortener')
    expect(page).to have_field('target_url')

    fill_in 'target_url', with: 'https://www.coingecko.com/en/coins/bitcoin'
    click_button 'Shorten'

    # Wait for AJAX response
    expect(page).to have_content('Success!', wait: 5)
    expect(page).to have_content('Short URL:')
    expect(page).to have_content('Target URL:', wait: 2)
    expect(page).to have_content('https://www.coingecko.com/en/coins/bitcoin')

    # Verify short URL is displayed
    short_url_input = find('[data-url-shortener-target="shortUrl"]')
    expect(short_url_input.value).to match(%r{http.*/[a-zA-Z0-9]+})
  end

  scenario 'User copies short URL to clipboard' do
    stub_request(:get, 'https://example.com')
      .to_return(body: '<html><head><title>Example</title></head></html>')
    visit root_path

    fill_in 'target_url', with: 'https://example.com'
    click_button 'Shorten'

    expect(page).to have_content('Success!', wait: 5)

    click_button 'Copy'

    expect(page).to have_content('Copied!', wait: 2)
  end

  scenario 'User sees error for invalid URL' do
    visit root_path

    fill_in 'target_url', with: 'not-a-valid-url'
    click_button 'Shorten'

    expect(page).to have_content('Invalid URL format', wait: 5)
  end

  scenario 'User sees error for empty URL' do
    visit root_path

    click_button 'Shorten'

    expect(page).to have_content('enter a URL', wait: 5)
  end

  scenario 'User sees recent URLs on homepage' do
    create_list(:short_url, 3)

    visit root_path

    expect(page).to have_content('Recent Short URLs')
    expect(page).to have_css('.space-y-4 > div', count: 3)
  end

  scenario 'User follows a short URL redirect' do
    short_url = create(:short_url, target_url: 'https://example.com')

    visit "/#{short_url.short_code}"

    # Should redirect
    expect(current_url).to eq('https://example.com/')
  end

  scenario 'User sees 404 for non-existent short code' do
    visit '/nonexistent'

    expect(page).to have_content('The page you were looking for doesn\'t exist')
  end

  scenario 'Short URL displays title if available' do
    visit root_path

    # Stub HTTP request for title fetching
    stub_request(:get, 'https://example.com')
      .to_return(body: '<html><head><title>Example Domain</title></head></html>')

    fill_in 'target_url', with: 'https://example.com'
    click_button 'Shorten'

    expect(page).to have_content('Success!', wait: 5)
    expect(page).to have_content('Page Title:', wait: 2)
    expect(page).to have_content('Example Domain')
  end
end
