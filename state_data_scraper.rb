require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'

root = "https://www.uspto.gov/web/offices/ac/ido/oeip/taf/st_co_"
years = ["92","93","94","95","96","97","98","99","00","01",
		"02","03","04","05","06","07","08","09","10","11",
		"12","13","14","15"]
usstates = ["ALABAMA", "ALASKA", "ARIZONA", "ARKANSAS", "CALIFORNIA", 
			"COLORADO", "CONNECTICUT", "DELAWARE", "FLORIDA", 
			"GEORGIA", "HAWAII", "IDAHO", "ILLINOIS", "INDIANA", 
			"IOWA", "KANSAS", "KENTUCKY", "LOUISIANA", "MAINE", 
			"MARYLAND", "MASSACHUSETTS", "MICHIGAN", "MINNESOTA", 
			"MISSISSIPPI", "MISSOURI", "MONTANA", "NEBRASKA", "NEVADA", 
			"NEW HAMPSHIRE", "NEW JERSEY", "NEW MEXICO", "NEW YORK", 
			"NORTH CAROLINA", "NORTH DAKOTA", "OHIO", "OKLAHOMA", 
			"OREGON", "PENNSYLVANIA", "RHODE ISLAND", "SOUTH CAROLINA", 
			"SOUTH DAKOTA", "TENNESSEE", "TEXAS", "UTAH", "VERMONT", 
			"VIRGINIA", "WASHINGTON", "WEST VIRGINIA", "WISCONSIN", 
			"WYOMING", "DISTRICT OF COLUMBIA"]
states = {}

years.each {|year|
	year_num = year.to_i
	page = Nokogiri::HTML(open(root+year.to_s+".htm"))
	if (year_num >90 || year_num < 02) then
		text = page.css('pre').text
		text.each_line { |line|
			if line =~ (/(\w\w)\s+(\w+(\s\w+)*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) && usstates.include?($2) && $1!="GE" then

				if(!states[$1]) then
					states[$1] = {}
				end
				if (year != "93")
					states[$1][year] = {"utility"=>$4.to_i,
									"design"=>$5.to_i,
									"plant"=>$6.to_i,
									"reissue"=>$7.to_i,
									"totals"=>$8.to_i,
									"SIRS"=>$9.to_i}
				else
					states[$1][year] = {"utility"=>$4.to_i,
									"design"=>$5.to_i,
									"plant"=>$6.to_i,
									"reissue"=>$7.to_i,
									"totals"=>$9.to_i,
									"SIRS"=>$8.to_i}
				end
			end
		}
	elsif (year_num>6 && year_num != 15)
		page.css("tr").each { |row|
			abv,n,uti,des,plt,rei,tot,sirs = nil,nil,nil,nil,nil,nil,nil,nil
			if row.css("td").size == 8 then
				abv,n,uti,des,plt,rei,tot,sirs = row.css("td").map{|x| x.text.chomp}
			else
				dummy,abv,n,uti,des,plt,rei,tot,sirs = row.css("td").map{|x| x.text.chomp}
			end

			if (usstates.include?(n)) then
				if (!states[abv]) then
					states[abv] = {}
				end
				states[abv][year] = {"utility"=>uti.to_i,
									"design"=>des.to_i,
									"plant"=>plt.to_i,
									"reissue"=>rei.to_i,
									"totals"=>tot.to_i,
									"SIRS"=>sirs.to_i}
			end
		}
	else
		page.css("tr").each { |row|
			dummy,abv,n,uti,des,plt,rei,tot = row.css("td").map{|x| x.text.chomp}

			if (usstates.include?(n)) then
				if (!states[abv]) then
					states[abv] = {}
				end
				states[abv][year] = {"utility"=>uti.to_i,
									"design"=>des.to_i,
									"plant"=>plt.to_i,
									"reissue"=>rei.to_i,
									"totals"=>tot.to_i,
									"SIRS"=>"Not Provided"}
			end
		}
	end
}

states.each { |s,h|
	CSV.open("sheets/"+s+"_patent_data.csv","wb") {|csv|
		csv << ["State","Year","Utility","Design","Plant","Reissue","Total","SIRS"]
		h.each { |year,data|
			fullyear = nil
			if year.to_i > 90 then 
				fullyear = "19"+year
			else 
				fullyear = "20"+year
			end
			csv << [s,fullyear,data["utility"],data["design"],data["plant"],
					data["reissue"],data["totals"],data["SIRS"]]
		}
	}

}
