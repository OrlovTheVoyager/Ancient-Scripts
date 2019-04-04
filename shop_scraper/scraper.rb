require 'httparty'
require 'nokogiri'
require 'json'
require 'byebug'
require 'yaml'

shop_config = "lego.yaml"
yaml_load = YAML.load_file("config/#{shop_config}")

catalog_url = yaml_load['catalog_url']
shop_name = yaml_load['shop_name'] 
link_class = yaml_load['link_class']
name_class = yaml_load['name_class'] 
price_class = yaml_load['price_class'] 
description_class = yaml_load['description_class'] 
img_class = yaml_load['img_class']
img_attr = yaml_load['img_attr']


# Scrapes single product page
def single_product_scraper(product_url, shop_name, name_class, price_class, description_class, img_class, img_attr)
    # Getting page HTML
    unparsed_page = HTTParty.get("#{product_url}")
    parsed_page = Nokogiri::HTML(unparsed_page)

    if parsed_page.css(name_class).first != nil && parsed_page.css(price_class).first != nil && parsed_page.css(description_class) != nil && parsed_page.css(img_class).attr(img_attr) != nil
        # Collecting info from parsed page
        product_name = parsed_page.css(name_class).first.text.gsub("\n","").gsub("\t", "").gsub("/", "")
        product_price = parsed_page.css(price_class).first.text.gsub("\n","").gsub("\t", "").gsub("/", "")
        product_description = parsed_page.css(description_class).text.gsub("\n","").gsub("\t", "").gsub("/", "")
        product_img = parsed_page.css(img_class).attr(img_attr).value
        
        # Creating json of the product
        json_product = {
            :shop_name => shop_name,
            :name => product_name,
            :price => product_price,
            :quantity => rand(100...1000),
            :description => product_description,
            :img => "/img/"+product_name+".jpg"
        }

        # Saving json and img to files
        File.open("json/#{product_name}.json", "w") do |line|
            line.puts json_product.to_json
        end
        File.open("img/#{product_name}.jpg", "wb") do |file| 
            file.write(HTTParty.get(product_img))
        end
        print "Done\n"
    else
        print "Failed\n"
    end
end


# Scrapes product catalog
def catalog_scraper(catalog_url, shop_name, link_class, name_class, price_class, description_class, img_class, img_attr)
    # Getting page HTML
    unparsed_page = HTTParty.get(catalog_url)
    parsed_page = Nokogiri::HTML(unparsed_page)

    products = parsed_page.css(link_class)

    puts "We found #{products.length} links of possible products!"
    puts "Enter from of products:"
    from = gets.to_i

    puts "Enter limit of products:"
    limit = gets.to_i
    if limit == 0
        limit = products.length
    end

    for i in from..limit
        product_url = products[i].attr("href")
        print "#{i} #{product_url}..."
        single_product_scraper(product_url, shop_name, name_class, price_class, description_class, img_class, img_attr)
        sleep(0.5)
    end
end

catalog_scraper(catalog_url, shop_name, link_class, name_class, price_class, description_class, img_class, img_attr)
