require 'bundler'
Bundler.require

require 'csv'

class NZOnAirScraper
  include Capybara::DSL

  def initialize
    Capybara.app = self
    Capybara.current_driver = :mechanize
    Capybara.run_server = false
    Capybara.app_host = 'http://www.nzonair.govt.nz'
  end

  def scrape!
    visit 'http://www.nzonair.govt.nz/search/funding/television/national-tv/?keyword=&date_from=&date_to=&broadcaster%5B%5D=&genre%5B%5D=&funding_type%5B%5D=&s=1#results'

     CSV.open('decisions.csv', 'wb') do |csv|

       csv << ['name', 'amount', 'date', 'production_company', 'channel', 'format', 'genre', 'fund_name']

      get_list.each do |result|
        puts result.values
        csv << result.values
      end

     end

  end

  private

  def check_school_assessment(school)
    visit school[:link]
    assessment = begin
                   find('.main-finding-block .highlight').text
                 rescue Capybara::ElementNotFound
                   nil
                 end

    report_download_link = begin
                             find('a.download-report-button')['href']
                           rescue Capybara::ElementNotFound
                             nil
                           end

    [school[:name], school[:link], assessment, 'http://ero.govt.nz' + report_download_link]
  end

  def get_list
    results = []

    next_button = true

    while next_button
      all('.grid .ml-m.block--stacked').each do |div|
        details = div.all('span.small').map(&:text)

        puts "#{div.find('h3').text} - #{div.find('p strong').text}"

        results << {
          name: div.find('h3').text,
          amount: div.find('p strong').text,
          date: details.first,
          production_company: details[1],
          channel: details[2],
          format: details[3],
          genre: details[4],
          fund_name: details.last
        }
      end

      next_button = first('a[data-analytics="|Show next"]')
      next_button.click if next_button
    end

    results
  end
end
