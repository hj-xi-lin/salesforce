public class UpdateCategoryOnAccountBatch implements Database.Batchable<sObject> {
    public final string query;
    
    public UpdateCategoryOnAccountBatch(string qry) {
        this.query = qry;
    }
    
    //This method will prepare Account Record to be updated based on Category 3.
    private static Account prepareAccount(Account ac) {
        string category = ac.Category_3__c;
        Switch on category {
            when 'Pharmacies','Car Dealer','Car Rental','DIY','Nurseries','Undertakers','Bedroom Stores','Bio-Stores','Flower Shops','Bowling Center','Bookstore','Office Supplies','Caravan Dealer','Cash-and-Carry','Discounter','Drugstores','Delicacy','Gyms','Photo Stores','Public baths','Parks','Hair Stylist','Garden Store','Gift Shop','Liquor Stores','Gambling','Golf Courses','Hearing Aid Stores','Jeans Shops','Jeweler','Department Stores','Movie Theaters','Kitchen Shopping','Shop','Leather Goods','Lettershops','Fashion Chain','Fashion Houses','Furniture Stores', 'Musical', 'Musical Instruments', 'Night Clubs', 'Fruit Veldgetables', 'Optician', 'Perfumeries', 'Furnishing', 'Health Food Store', 'Tire Retailer', 'Sanitary', 'Medical supplies store', 'Ship Tourism', 'Shoe Stores', 'Cableways', 'Skiing center', '1€ Stores', 'Tanning Salons', 'Toy Stores', 'Sport Stores', 'Supermarkets', 'Tobacco wholesale', 'Tobacco', 'Gas Stations', 'Technology Stores', 'Tea Parties', 'Telephone Company', 'Phone Stores', 'Telecommunications', 'Carpet Shopping', 'Animal Feed', 'Animal Shelters', 'Underwear', 'Videostore', 'Public banks', 'Washes', 'Zoos', 'Zoo Stores', 'Office Market', 'Travel Agencies', 'Pet Shop', 'Drugstore', 'Tour Operators' {
                switch on category {
                    when 'Optician','Pharmacies' { ac.X2020_Reference_Clients__c = 'Bilfinger, Deutsche Bahn, Coca-Cola'; }
					when 'Animal Feed','Fruit Veldgetables' { ac.X2020_Reference_Clients__c = 'Coca-Cola, Burger King, WMF'; }
					when 'Tea Parties','Tobacco' { ac.X2020_Reference_Clients__c = 'Coca-Cola, Schloss-Quelle Mellis, SAGASSER'; }
					when 'Animal Shelters' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Bundeswehr, Leipziger Verkehrsbetriebe'; }
					when 'Lettershops' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Deutsche Post, DPD'; }
					when 'Ship Tourism','Tour Operators','Travel Agencies' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Lufthansa, WISAG'; }
					when 'Bio-Stores','Cash-and-Carry','Delicacy','Discounter','Health Food Store','Liquor Stores','Supermarkets' { ac.X2020_Reference_Clients__c = 'EDEKA, real, Feneberg'; }
					when 'Undertakers' { ac.X2020_Reference_Clients__c = 'Helios Kliniken, Kursana, DRK'; }
					when 'Furnishing','Office Supplies','Bedroom Stores','Carpet Shopping','Furniture Stores','Kitchen Shopping' { ac.X2020_Reference_Clients__c = 'Höffner, POCO, Roller'; }
					when 'Bowling Center','Gambling','Golf Courses','Gyms','Hair Stylist','Movie Theaters','Musical','Parks','Tanning Salons','Videostore','Zoos' { ac.X2020_Reference_Clients__c = 'Holmes Place, Burger King, Casino Merkur Spielothek'; }
					when 'Gift Shop','1€ Stores','Department Stores','Drugstores','Office Market','Pet Shop','Toy Stores','Zoo Stores' { ac.X2020_Reference_Clients__c = 'KaDeWe, DECATHLON'; }
					when 'Leather Goods','Underwear','Fashion Chain','Fashion Houses','Jeans Shops','Shoe Stores','Sport Stores' { ac.X2020_Reference_Clients__c = 'KaDeWe, Marc O\'Polo, DECATHLON'; }
					when 'Sanitary','Cableways' { ac.X2020_Reference_Clients__c = 'Lufthansa, LEONHARD WEISS, Bilfinger'; }
					when 'Night Clubs' { ac.X2020_Reference_Clients__c = 'NORDSEE, Burger King, Mövenpick'; }
					when 'DIY','Flower Shops','Garden Store','Bookstore' { ac.X2020_Reference_Clients__c = 'DECATHLON, Höffner'; }
					when 'Jeweler','Perfumeries' { ac.X2020_Reference_Clients__c = 'WMF, LVMH, L\'OCCITANE'; }
					when 'Musical Instruments' { ac.X2020_Reference_Clients__c = 'WMF, Electrolux, VW'; }
					when 'Car Rental','Car Dealer','Caravan Dealer','Gas Stations','Tire Retailer','Washes' { ac.X2020_Reference_Clients__c = 'VW, Sixt, A.T.U'; }
					when 'Telecommunications','Telephone Company','Phone Stores','Photo Stores','Technology Stores' { ac.X2020_Reference_Clients__c = 'Unitymedia BW, Telefonica Germany , freenet'; }
                }
                ac.HeyJobs_Category__c = 'Retail';
            }
            when 'Rail Companies', 'Bus Company', 'Courier Services', 'Logistics', 'Pizza Service', 'Spedition', 'Taxi companies', 'Transport Network', 'Packaging Industry', 'Load', 'Freight Forwarders', 'Furniture Shipping', 'Car Cranes', 'Harbors' {
				switch on category {
					when 'Courier Services','Freight Forwarders','Harbors','Logistics','Furniture Shipping' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Deutsche Post, DPD'; }
					when 'Transport Network','Bus Company','Rail Companies' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Lufthansa, WISAG'; }
					when 'Packaging Industry' { ac.X2020_Reference_Clients__c = 'Deutsche Post, DPD, Axel Springer'; }
					when 'Load' { ac.X2020_Reference_Clients__c = 'KaDeWe, DECATHLON'; }
					when 'Pizza Service' { ac.X2020_Reference_Clients__c = 'NORDSEE, Burger King, Mövenpick'; }
					when 'Car Cranes' { ac.X2020_Reference_Clients__c = 'VW, Sixt, A.T.U'; }
				}
                ac.HeyJobs_Category__c = 'Logistics';
            }
            when 'Call center','Customer Care' {
				if(category == 'Call center') { ac.X2020_Reference_Clients__c = 'SNT Deutschland, Sitel, Concentrix'; }
                ac.HeyJobs_Category__c = 'Call center';
            }
            when 'Demolition Company', 'Waste', 'Airlines', 'Airports', 'Car Paintwork', 'Car service', 'Basketball Teams', 'Caterer', 'Event Agencies', 'Building Service', 'Craftsman', 'Hygiene Service', 'Industry Service', 'Truck Service', 'Exhibition Companies', 'Cleaning Companies', 'Security Services', 'Housing Companies', 'Ports', 'Waterparks' {
				switch on category {
					when 'Airlines','Airports' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Lufthansa, WISAG'; }
					when 'Demolition Company','Waste' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, REMONDIS, ReFood'; }
					when 'Building Service','Industry Service','Housing Companies','Security Services' { ac.X2020_Reference_Clients__c = 'SECURITAS, COWA Service, RDG Gebäudeservice'; }
					when 'Basketball Teams','Waterparks' { ac.X2020_Reference_Clients__c = 'Holmes Place, Burger King, Casino Merkur Spielothek'; }
					when 'Craftsman' { ac.X2020_Reference_Clients__c = 'Lufthansa, LEONHARD WEISS, Bilfinger'; }
					when 'Caterer' { ac.X2020_Reference_Clients__c = 'NORDSEE, Burger King, Mövenpick'; }
					when 'Event Agencies','Exhibition Companies' { ac.X2020_Reference_Clients__c = 'Schwarz & Bold, cadooz, Raven51'; }
					when 'Car Paintwork','Car Service','Truck Service' { ac.X2020_Reference_Clients__c = 'VW, Sixt, A.T.U'; }
					when 'Hygiene Service','Cleaning Companies' { ac.X2020_Reference_Clients__c = 'WISAG, Remondis, COWA Service'; }
				}
                ac.HeyJobs_Category__c = 'Services';
            }
            when 'Sheltered Workshop', 'Kita', 'Radiology Practices', 'Hospitals', 'Laboratories', 'Medical', 'Care Services', 'Care Homes', 'Radiology', 'Dental labs', 'Rehabilitation clinics', 'Emergency Services', 'Social Facilities', 'Animal Hospitals', 'Medical Services', 'Dental Laboratories' {
				switch on category {
					when 'Animal Hospitals' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Bundeswehr, Leipziger Verkehrsbetriebe'; }
					when 'Care Homes','Care Services','Dental Laboratories','Hospitals','Laboratories','Medical Services','Rehabilitation clinics','Emergency Services','Kita','Sheltered Workshop','Social Facilities' { ac.X2020_Reference_Clients__c = 'Helios Kliniken, Kursana, DRK'; }
					when 'Medical' { ac.X2020_Reference_Clients__c = 'Helios Kliniken, Kursana, Electrolux'; }
				}
                ac.HeyJobs_Category__c = 'Healthcare';
            }
            when 'Contract Manufacturers','Temporary Employment Agencies' {
                switch on category {
                    when 'Temporary Employment Agencies' { ac.X2020_Reference_Clients__c = 'Adecco, STUDITEMPS, Diwa Personalservice'; }
                    when 'Contract Manufacturers' { ac.X2020_Reference_Clients__c = 'Bilfinger, Remondis, VW'; }
                }
                ac.HeyJobs_Category__c = 'Temporary Employment Agencies';
            }
            when 'Farms', 'Aluminum Plants', 'Plant Engineering', 'Tire Manufacturers', 'Elevator Manufacturer', 'Car manufacturers', 'Construction', 'Building Materials Industry', 'Building Contractors', 'Mining', 'Sheet Metal Parts', 'Brown Goods', 'Glasses', 'Bread Factories', 'Office Articles', 'Office Furniture', 'Chemical Wholesale', 'Computer', 'Printers', 'Railway Engineering', 'Bicycle Manufacturer', 'Paint Manufacturers', 'Feathers', 'Gourmet Food Manufacturer', 'Window Manufacturers', 'Prefabricated Houses', 'Fire Fighting Equipment', 'Fish Factories', 'Meat Products', 'Aircraft manufacturers', 'Forest Enterprise', 'Leisure Products', 'Fork-Lift Truck', 'Gardening', 'Poultry Holdings', 'Spice Manufacturer', 'Drinks wholesale', 'Foundries', 'Glassmaker', 'Basic Chemicals', 'Semiconductor Industry', 'Household Chemistry', 'Household Goods', 'Home Textiles', 'Wood Industry', 'Hydraulic', 'Cable Manufacturer', 'Camera Maker', 'Gravel Plant', 'Prams Industrial', 'Components', 'Crane Technology', 'Kitchen Manufacturer', 'Book Publishers', 'Automation', 'Beverage Industry','Plastic Parts', 'Store builder', 'Warehouse Equipment', 'Agricultural Machinery', 'Agricultural Technics', 'Foods', 'Light Manufacturer', 'Machine Builders', 'Fair Construction', 'Petroleum Houses', 'Furniture Industry', 'Dairies', 'Grinding Plants', 'Music Industry', 'Van manufacturers', 'Surface Technology', 'Optoelectronics', 'Paper Mills', 'Paper Wholesale', 'Perfume Industry', 'Porcelain Factory', 'Pump Manufacturer', 'Recycling', 'Shipping companies', 'Tire Manufacturer', 'Defense Industry', 'Coffin Maker', 'Jewelry Manufacturer', 'Footwear Industry', 'Solar Power', 'Toymaker', 'Spirits', 'Sporting Goods', 'Steel engineering', 'Steel Wholesale', 'Steel Processing', 'Steelworks', 'Material Manufacturer', 'Confectionary', 'Tobacco Industry', 'Technical Ceramics', 'Textile Industry', 'PBX Manufacturer', 'Stairlifts', 'Watchmaker', 'Fans', 'Connection Technology', 'Wineries', 'White Goods', 'Shipyards', 'Tooling', 'Tool Manufacturers', 'Wind Power', 'Camping Van manufacturers', 'Cement Industry', 'Machining', 'Car Suppliers', 'Brick Industry', 'Car Manufacturers', 'Steel Fabricators','Builder\'s Merchant' {
                switch on category {
                    when 'Book Publishers', 'Music Industry' { ac.X2020_Reference_Clients__c = 'Axel Springer, ZENIT, Süddeutsche Zeitung'; }
                    when 'Basic Chemicals','Household Chemistry','Paint Manufacturers','Chemical Wholesale' { ac.X2020_Reference_Clients__c = 'Bilfinger, Remondis, VW'; }
                    when 'Light Manufacturer','Automation','Cable Manufacturer','Optoelectronics','Semiconductor Industry' { ac.X2020_Reference_Clients__c = 'Bosch, ABB, Lufthansa'; }
					when 'Confectionary','Dairies','Farms','Fish Factories','Foods','Forest Enterprise','Gourmet Food Manufacturer','Grinding Plants','Meat Products','PBX Manufacturer','Poultry Holdings','Spice Manufacturer' { ac.X2020_Reference_Clients__c = 'Coca-Cola, Burger King, WMF'; }
					when 'Beverage Industry','Spirits','Tobacco Industry','Wineries' { ac.X2020_Reference_Clients__c = 'Coca-Cola, Schloss-Quelle Mellis, SAGASSER'; }
					when 'Furniture Industry','Shipping Companies' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Deutsche Post, DPD'; }
					when 'Aircraft manufacturers','Railway Engineering','Shipyards' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Lufthansa, WISAG'; }
					when 'Recycling' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, REMONDIS, ReFood'; }
					when 'Paper Mills','Wood Industry','Paper Wholesale' { ac.X2020_Reference_Clients__c = 'Deutsche Post, DPD, Axel Springer'; }
					when 'Fair Construction' { ac.X2020_Reference_Clients__c = 'SECURITAS, COWA Service, RDG Gebäudeservice'; }
					when 'Coffin Maker','Kitchen Manufacturer','Office Furniture','Home Textiles' { ac.X2020_Reference_Clients__c = 'Höffner, POCO, Roller'; }
					when 'Bread Factories' { ac.X2020_Reference_Clients__c = 'K&U Bäckerei, Meisterbäckerei Steinecke, Sternenbäck'; }
					when 'Footwear Industry','Sporting Goods','Textile Industry' { ac.X2020_Reference_Clients__c = 'KaDeWe, Marc O\'Polo, DECATHLON'; }
					when 'Aluminum Plants','Brick Industry','Construction','Cement Industry','Connection Technology','Foundries','Glassmaker','Gravel Plant','Steel Processing','Steelworks','Surface Technology','Window Manufacturers','Material Manufacturer','Plastic Parts','Sheet Metal Parts','Technical Ceramics','Tool Manufacturers','Tooling','Warehouse Equipment','Building Contractors','Prefabricated Houses','Steel Fabricators','Steel Wholesale','Building Materials Industry' { ac.X2020_Reference_Clients__c = 'Lufthansa, LEONHARD WEISS, Bilfinger'; }
					when 'Mining','Plant Engineering' { ac.X2020_Reference_Clients__c = 'Lufthansa, VW, Schindler Deutschland'; }
					when 'Builder\'s Merchant' { ac.X2020_Reference_Clients__c = 'DECATHLON, Höffner'; }
					when 'Jewelry Manufacturer','Perfume Industry','Porcelain Factory','Watchmaker' { ac.X2020_Reference_Clients__c = 'WMF, LVMH, L\'OCCITANE'; }
					when 'Brown Goods','Camera Maker','Computer','Glasses','Household Goods','Leisure Products','Prams Industrial','Toymaker','White Goods' { ac.X2020_Reference_Clients__c = 'WMF, Electrolux, VW'; }
					when 'Agricultural Machinery','Crane Technology','Defense Industry','Elevator Manufacturer','Fans','Feathers','Fire Fighting Equipment','Fork-Lift Truck','Hydraulic','Machine Builders','Machining','Pump Manufacturer' { ac.X2020_Reference_Clients__c = 'VW, Bilfinger, Lufthansa'; }
					when 'Petroleum Houses' { ac.X2020_Reference_Clients__c = 'VW, Sixt, A.T.U'; }
					when 'Camping Van manufacturers','Car manufacturers','Car Suppliers','Tire Manufacturer','Van manufacturers','Bicycle Manufacturer' { ac.X2020_Reference_Clients__c = 'VW, Sixt, Mercedes-Benz Vertrieb'; }
					when 'Components' { ac.X2020_Reference_Clients__c = 'VW, LEONHARD WEISS, Hagedorn'; }
					when 'Printers' { ac.X2020_Reference_Clients__c = 'Unitymedia BW, Telefonica Germany , freenet'; }
					when 'Solar Power','Wind Power' { ac.X2020_Reference_Clients__c = 'Stadtwerke Bielefeld, Bayernwerk Netz, Enpal'; }
                }
                ac.HeyJobs_Category__c = 'Production';
            }
            when 'Hotel Chains', 'Camping Sites', 'Hotels', 'Bakery', 'Brewery', 'Breweries', 'Butcher', 'Coffee Distributor', 'Coffee Shops', 'Confiserie', 'Seafood Restaurants', 'Steakhouses', 'Theme Restaurant', 'Traffic Gastronomy', 'Wine Merchant', 'Systematic Gastronomy', 'Franchisee' {
				switch on category {
					when 'Breweries','Coffee Distributor','Camping Sites' { ac.X2020_Reference_Clients__c = 'Coca-Cola, Schloss-Quelle Mellis, SAGASSER'; }
					when 'Butcher','Confiserie','Wine Merchant' { ac.X2020_Reference_Clients__c = 'EDEKA, real, Feneberg'; }
					when 'Hotel Chains','Hotels' { ac.X2020_Reference_Clients__c = 'Intercontinental, Holiday-Inn, H-Hotels'; }
					when 'Bakery' { ac.X2020_Reference_Clients__c = 'K&U Bäckerei, Meisterbäckerei Steinecke, Sternenbäck'; }
					when 'Brewery','Coffee Shops','Seafood Restaurants','Steakhouses','Systematic Gastronomy','Theme Restaurant','Traffic Gastronomy','Franchisee' { ac.X2020_Reference_Clients__c = 'NORDSEE, Burger King, Mövenpick'; }
				}
                ac.HeyJobs_Category__c = 'Hospitality';
            }
            when 'Headhunter' {
				ac.X2020_Reference_Clients__c = 'Adecco, STUDITEMPS, Diwa Personalservice';
                ac.HeyJobs_Category__c = 'Headhunter';
            }
            when 'Job promotion', 'SEO Agency', 'Advertising Agencies' {
                switch on category {
                    when 'Job promotion' { ac.X2020_Reference_Clients__c = 'Adecco, STUDITEMPS, Diwa Personalservice'; }
					when 'Advertising Agencies','SEO Agency' { ac.X2020_Reference_Clients__c = 'Schwarz & Bold, cadooz, Raven51'; }
                }
                ac.HeyJobs_Category__c = 'Agency';
            }
            when 'Professional Fire', 'Professional Association', 'Federal Offices', 'Unions', 'Associations', 'Chambers', 'Parties', 'Consumer Organizations' {
                if(category == 'Consumer Organizations' || category == 'Professional Association' || category == 'Associations' || category == 'Chambers' || category == 'Federal Offices' || category == 'Parties' || category == 'Professional Fire') { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Bundeswehr, Leipziger Verkehrsbetriebe'; }
                ac.HeyJobs_Category__c = 'Public Sector';
            }
            when 'Architects', 'Computer Games', 'Electrical Engineering', 'Electrical Parts', 'EMS', 'Engineering', 'Financial Funds', 'Research Centers', 'Generics', 'Universities', 'Engineers', 'IT Consulting', 'Lawyer', 'Marine Technology', 'Building Technology', 'Measuring Control Equipment', 'Pharmaceutical Industry', 'PR Agencies', 'Tester', 'Training', 'Software Manufacturer', 'Management Consultant', 'Auditors', 'Trustee', 'Investors', 'Payment Processor' {
                switch on category {
                    when 'Auditors','IT Consulting','Management Consultant','Lawyer' { ac.X2020_Reference_Clients__c = 'Arvato Systems, BTC Business Technology Consulting, Lufthansa'; }
                    when 'Research Centers','Tester','Training','Universities' { ac.X2020_Reference_Clients__c = 'Axel Springer, DRK, DeutschAkademie Sprachschule'; }
                    when 'Generics','Pharmaceutical Industry' { ac.X2020_Reference_Clients__c = 'Bilfinger, Deutsche Bahn, Coca-Cola';}
                    when 'Engineering','Electrical Engineering','Electrical Parts','EMS','Measuring Control Equipment' { ac.X2020_Reference_Clients__c = 'Bosch, ABB, Lufthansa'; }
					when 'Financial Funds','Investors','Payment Processor','Trustee' { ac.X2020_Reference_Clients__c = 'Deutsche Bank, KS Sparkassen Finanzdienstleistungen, Umweltbank'; }
					when 'Computer Games','Software Manufacturer' { ac.X2020_Reference_Clients__c = 'Hewlett-Packard, Zalando, Auto1'; }
					when 'Building Technology','Architects','Engineers' { ac.X2020_Reference_Clients__c = 'Lufthansa, LEONHARD WEISS, Bilfinger'; }
					when 'PR Agencies' { ac.X2020_Reference_Clients__c = 'Schwarz & Bold, cadooz, Raven51'; }
					when 'Marine Technology' { ac.X2020_Reference_Clients__c = 'VW, Bilfinger, Lufthansa'; }
                }
                ac.HeyJobs_Category__c = 'High-End';
            }
            when 'Car banks', 'Construction Machine Retail', 'Flower Wholesale', 'Publishers', 'Hockey Teams', 'Electrical Wholesalers', 'Trade Publishers', 'TV Channel', 'Film Studios', 'Football Clubs', 'Prisons', 'Wholesale Grosso', 'Wholesale-Other', 'Wholesale Technique', 'Large Consumers', 'Real Estate Companies', 'Real Estate Agents', 'Collection', 'TV channels', 'Estate trading', 'Leasing', 'Market Research', 'Grid Companies', 'NGO', 'Pharma Wholesale', 'Radio stations', 'Plumbing Wholesale', 'Showman', 'Sports Clubs', 'Translation', 'City ​​Marketing', 'Provider', 'Advertising sales', 'Economic Information', 'Newspaper Publishers', 'Waterworks', 'Estates', 'Theatre', 'Auto Parts Trade', 'Buying Group', 'Gastro Outfitters', 'Hairdresser Wholesale', 'Wholesale Cleaning', 'Museums', 'Libraries' {
                switch on category {
                    when 'Translation','Market Research' { ac.X2020_Reference_Clients__c = 'Axel Springer, DRK, DeutschAkademie Sprachschule'; }
                    when 'Economic Information','Newspaper Publishers','Radio stations','Trade Publishers','TV Channel','Wholesale Grosso' { ac.X2020_Reference_Clients__c = 'Axel Springer, ZENIT, Süddeutsche Zeitung'; }
                    when 'Pharma Wholesale' { ac.X2020_Reference_Clients__c = 'Bilfinger, Deutsche Bahn, Coca-Cola'; }
                    when 'Electrical Wholesalers' { ac.X2020_Reference_Clients__c = 'Bosch, ABB, Lufthansa'; }
					when 'Large Consumers' { ac.X2020_Reference_Clients__c = 'Coca-Cola, Burger King, WMF'; }
					when 'Libraries','NGO','Prisons' { ac.X2020_Reference_Clients__c = 'Deutsche Bahn, Bundeswehr, Leipziger Verkehrsbetriebe'; }
					when 'Collection','Leasing' { ac.X2020_Reference_Clients__c = 'Deutsche Bank, KS Sparkassen Finanzdienstleistungen, Umweltbank'; }
					when 'Film Studios' { ac.X2020_Reference_Clients__c = 'SECURITAS, COWA Service, RDG Gebäudeservice'; }
					when 'Estates','Real Estate Companies', 'Real Estate Agents' { ac.X2020_Reference_Clients__c = 'SECURITAS, Intercontinental, EDEKA'; }
					when 'Football Clubs','Hockey Teams','Museums','Sports Clubs','Theatre' { ac.X2020_Reference_Clients__c = 'Holmes Place, Burger King, Casino Merkur Spielothek'; }
					when 'Buying Group','Construction Machine Retail' { ac.X2020_Reference_Clients__c = 'KaDeWe, DECATHLON'; }
					when 'Gastro Outfitters' { ac.X2020_Reference_Clients__c = 'NORDSEE, Burger King, Mövenpick'; }
					when 'Flower Wholesale','Plumbing Wholesale','Wholesale Technique','Wholesale-Other' { ac.X2020_Reference_Clients__c = 'DECATHLON, Höffner'; }
					when 'Advertising Sales' { ac.X2020_Reference_Clients__c = 'Schwarz & Bold, cadooz, Raven51'; }
					when 'Hairdresser Wholesale' { ac.X2020_Reference_Clients__c = 'WMF, LVMH, L\'OCCITANE'; }
					when 'Auto Parts Trade' { ac.X2020_Reference_Clients__c = 'VW, Sixt, A.T.U'; }
					when 'Wholesale Cleaning' { ac.X2020_Reference_Clients__c = 'WISAG, Remondis, COWA Service'; }
					when 'Grid Companies','Provider','Waterworks' { ac.X2020_Reference_Clients__c = 'Stadtwerke Bielefeld, Bayernwerk Netz, Enpal'; }
                }
                ac.HeyJobs_Category__c = 'Office';
            }
            when 'Sparkasse', 'Banks', 'Bausparkasse', 'Development Banks','Insurance', 'Development Bank', 'Health Insurance', 'Insurance Broker', 'Private Banks' {
                switch on category {
                    when 'Insurance','Health Insurance','Insurance Broker' { ac.X2020_Reference_Clients__c = 'Allianz Nord-Ost, Provinzial Rheinland Versicherung, Sparkasse'; }
					when 'Banks','Bausparkasse','Development Bank','Private Banks','Sparkasse' { ac.X2020_Reference_Clients__c = 'Deutsche Bank, KS Sparkassen Finanzdienstleistungen, Umweltbank'; }
                }
                ac.HeyJobs_Category__c = 'Banking and Insurance';
            }
            when 'e-Commerce','Internet Companies' {
                if(category == 'e-Commerce') { ac.X2020_Reference_Clients__c = 'Zalando, momox, notebooksbilliger.de'; }
                ac.HeyJobs_Category__c = 'E-commerce';
            }
			when 'Cable Companies' {
				ac.X2020_Reference_Clients__c = 'Bosch, ABB, Lufthansa';
                ac.HeyJobs_Category__c = 'Office';
			}
			when 'Landscaping' {
				ac.X2020_Reference_Clients__c = 'SECURITAS, COWA Service, RDG Gebäudeservice';
                ac.HeyJobs_Category__c = 'Services';
			}
			when 'Hearing Care' {
				ac.X2020_Reference_Clients__c = 'Helios Kliniken, Kursana, DRK';
                ac.HeyJobs_Category__c = 'Healthcare';
			}
			when 'City Marketing' {
				ac.X2020_Reference_Clients__c = 'Schwarz & Bold, cadooz, Raven51';
			}
			when 'Taxi Services' {
				ac.X2020_Reference_Clients__c = 'VW, Sixt, A.T.U';
                ac.HeyJobs_Category__c = 'Services';
			}
        }
        return ac;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> accList) {
        if(!accList.isEmpty()) {
            List<Account> accToUpdate = new List<Account>();
            for(Account ac : accList) 
            {
                if(ac.Category_3__c != null && !string.isEmpty(ac.Category_3__c)) 
                {
                    Account acc = prepareAccount(ac);
                    if(acc.recordtype.name == 'Inventory Partner') {
                        acc.HeyJobs_Category__c = 'Inventory Partner';
                    }
                    accToUpdate.add(acc);
                }
            }
            system.debug('--Final Account List'+accToUpdate.size());
            if(!accToUpdate.isEmpty()) {
                update accToUpdate;
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}