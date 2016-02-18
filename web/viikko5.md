Jatkamme sovelluksen rakentamista siitä, mihin jäimme viikon 4 lopussa. Allaoleva materiaali olettaa, että olet tehnyt kaikki edellisen viikon tehtävät. Jos et tehnyt kaikkia tehtäviä, voit ottaa kurssin repositorioista [edellisen viikon mallivastauksen](https://github.com/mluukkai/WebPalvelinohjelmointi2016/tree/master/malliv/viikko4). Jos sait suurimman osan edellisen viikon tehtävistä tehtyä, saattaa olla helpointa, että täydennät vastaustasi mallivastauksen avulla.

Jos otat edellisen viikon mallivastauksen tämän viikon pohjaksi, kopioi hakemisto muualle kurssirepositorion alta (olettaen että olet kloonannut sen) ja tee sovelluksen sisältämästä hakemistosta uusi repositorio.

**Huom:** muutamilla Macin käyttäjillä oli ongelmia Herokun tarvitseman pg-gemin kanssa. Paikallisesti gemiä ei tarvita ja se määriteltiinkin asennettavaksi ainoastaan tuotantoympäristöön. Jos ongelmia ilmenee, voit asentaa gemit antamalla <code>bundle install</code>-komentoon seuraavan lisämääreen:

    bundle install --without production

Tämä asetus muistetaan jatkossa, joten pelkkä `bundle install` riittää kun haluat asentaa uusia riippuvuuksia.

## Mashup: baarien haku

Suuri osa internetin palveluista hyödyntää nykyään joitain avoimia rajapintoja, joiden tarjoaman datan avulla sovellukset voivat rikastaa omaa toiminnallisuuttaan.

Myös oluihin liittyviä avoimia rajapintoja on tarjolla, ks. http://www.programmableweb.com/ hakusanalla beer

Tämän hetken tarjolla olevista rajapinnoista parhaalta näyttää http://www.programmableweb.com/api/brewery-db
jonka ilmainen käyttö on kuitenkin rajattu 400 päivittäiseen kyselyyn, joten emme tällä kertaa käytä sitä, vaan Beermapping API:a (ks. http://www.programmableweb.com/api/beer-mapping ja http://beermapping.com/api/), joka tarjoaa mahdollisuuden oluita tarjoilevien ravintoloiden tietojen etsintään.

Beermapingin API:a käyttävät sovellukset tarvitsevat yksilöllisen API-avaimen. Saat avaimen sivulta [http://beermapping.com/api/request_key](http://beermapping.com/api/request_key), vastaava käytäntö on olemassa hyvin suuressa osassa nykyään tarjolla olevissa avoimissa rajapinnoissa.

API:n tarjoamat palvelut on listattu sivulla [http://beermapping.com/api/reference/](http://beermapping.com/api/reference/)

Saamme esim. selville tietyn paikkakunnan olutravintolat tekemällä HTTP-get-pyynnön osoitteeseen <code>http://beermapping.com/webservice/loccity/[apikey]/[city]<location></code>

Paikkakunta siis välitetään osana URL:ia.

Kyselyjen tekemistä voi kokeilla selaimella tai komentoriviltä curl-ohjelmalla. Saamme esimerkiksi Espoon olutravintolat selville seuraavasti:

```ruby
mbp-18:ratebeer mluukkai$ curl http://beermapping.com/webservice/loccity/96ce1942872335547853a0bb3b0c24db/espoo
<?xml version='1.0' encoding='utf-8' ?><bmp_locations><location><id>12411</id><name>Gallows Bird</name><status>Brewery</status><reviewlink>http://beermapping.com/maps/reviews/reviews.php?locid=12411</reviewlink><proxylink>http://beermapping.com/maps/proxymaps.php?locid=12411&amp;d=5</proxylink><blogmap>http://beermapping.com/maps/blogproxy.php?locid=12411&amp;d=1&amp;type=norm</blogmap><street>Merituulentie 30</street><city>Espoo</city><state></state><zip>02200</zip><country>Finland</country><phone>+358 9 412 3253</phone><overall>91.66665</overall><imagecount>0</imagecount></location></bmp_locations>mbp-18:ratebeer mluukkai$
```

Kuten huomaamme, vastaus tulee XML-muodossa. Käytänne on hieman vanhahtava, sillä tällä hetkellä ylivoimaisesti suosituin web-palveluiden välillä käytettävä tiedonvaihdon formaatti on json.

Selaimella näemme palautetun XML:n hieman ihmisluettavammassa muodossa:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-1.png)

**HUOM: älä käytä tässä näytettyä API-avainta vaan rekisteröi itsellesi oma avain.**

**HUOM2:** palvelu on ajoittain _erittäin_ hidas. Voitkin käyttää sen sijaan saman datan tarjoavaa kurssia varten tehtyä,  osoitteessa
http://stark-oasis-9187.herokuapp.com/api/ toimivaa 'välimuistipalvelinta'. Esim. Helsingin tiedot saat välimuistipalvelimelta urlista
[http://stark-oasis-9187.herokuapp.com/api/helsinki]
(http://stark-oasis-9187.herokuapp.com/api/helsinki)

Välimuistipalvelin toimii siten, että jos siltä haetaan kaupunkia, jota on haettu jo aiemmin, palauttaa se tallettamansa tuloksen. Jos taas haetaan kaupunkia, jonka tietoja välimuistpalvelin ei tiedä, kysyy se kaupungin tiedot ensin Beermapping-palvelulta. Tällöin operaatio kestää huomattavasti kauemmin. Välimuistipalvelinta ei ole testattu kovin paljoa, joten sen toiminnassa voi ilmetä ongelmia. Jos näin tapahtuu, ilmoita asiasta.

Tehdään nyt sovellukseemme olutravintoloita etsivä toiminnallisuus.

Luodaan tätä varten sivu osoitteeseen places, eli määritellään route.rb:hen

    get 'places', to: 'places#index'

ja luodaan kontrolleri:

```ruby
class PlacesController < ApplicationController
  def index
  end
end
```

ja näkymä app/views/places/index.html.erb, joka aluksi ainoastaan näyttää hakuun tarvittavan lomakkeen:

```erb
<h1>Beer places search</h1>

<%= form_tag places_path do %>
  city <%= text_field_tag :city, params[:city] %>
  <%= submit_tag "Search" %>
<% end %>
```

Lomake siis lähettää HTTP POST -kutsun places_path:iin. Määritellään tälle oma reitti routes.rb:hen

    post 'places', to:'places#search'

Päätimme siis että metodin nimi on <code>search</code>. Laajennetaan kontrolleria seuraavasti:

```ruby
class PlacesController < ApplicationController
  def index
  end

  def search
    render :index
  end
end
```

Ideana on se, että <code>search</code>-metodi hakee panimoiden listan beermapping API:sta, jonka jälkeen panimot listataan index.html:ssä eli tämän takia metodin <code>search</code> lopussa renderöidään näkymätemplate <code>index</code>.

Kontrollerista metodissa <code>search</code> on siis tehtävä HTTP-kysely beermappin API:n sivulle. Paras tapa HTTP-kutsujen tekemiseen Rubyllä on HTTParty-gemin käyttö ks. https://github.com/jnunemaker/httparty. Lisätään seuraava Gemfileen:

    gem 'httparty'

Otetaan uusi gem käyttöön suorittamalla komentoriviltä tuttu komento <code>bundle install</code>

Kokeillaan nyt etsiä konsolista käsin Helsingin ravintoloita (muista uudelleenkäynnistää konsoli):

```ruby
2.2.1 :001 > api_key = "96ce1942872335547853a0bb3b0c24db"
2.2.1 :002 > url = "http://beermapping.com/webservice/loccity/#{api_key}/"
2.2.1 :003 > HTTParty.get url+"helsinki"
```

**HUOM:** voit siis nyt ja jatkossa käyttää vaihtoehtoisesti välimuistipalvelinta eli määritellä <code>url = 'http://stark-oasis-9187.herokuapp.com/api/'</code>

Kutsu siis palauttaa luokan <code>HTTParty::Response</code>-olion. Oliolta voidaan kysyä esim. vastaukseen liittyvät headerit:

```ruby
2.2.1 :004 > response = HTTParty.get url+"helsinki"
2.2.1 :005 > response.headers
 => {"date"=>["Sat, 07 Feb 2016 12:20:01 GMT"], "server"=>["Apache"], "expires"=>["Mon, 26 Jul 1997 05:00:00 GMT"], "last-modified"=>["Sat, 07 Feb 2016 12:20:01 GMT"], "cache-control"=>["no-store, no-cache, must-revalidate", "post-check=0, pre-check=0"], "pragma"=>["no-cache"], "vary"=>["Accept-Encoding"], "content-length"=>["4887"], "connection"=>["close"], "content-type"=>["text/xml"]}
2.2.1 :006 >
```

ja HTTP-kutsun statuskoodi:

```ruby
2.2.1 :006 > response.code
 => 200
```

Statuskoodi ks. http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html on tällä kertaa 200 eli ok, kutsu on siis onnistunut.

Vastausolion metodi <code>parsed_response</code> palauttaa metodin palauttaman datan rubyn hashina:

```ruby
2.2.1 :007 > response.parsed_response
 => {"bmp_locations"=>{"location"=>[{"id"=>"6742", "name"=>"Pullman Bar", "status"=>"Beer Bar", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=6742", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=6742&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=6742&d=1&type=norm", "street"=>"Kaivokatu 1", "city"=>"Helsinki", "state"=>nil, "zip"=>"00100", "country"=>"Finland", "phone"=>"+358 9 0307 22", "overall"=>"72.500025", "imagecount"=>"0"}, {"id"=>"6743", "name"=>"Belge", "status"=>"Beer Bar", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=6743", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=6743&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=6743&d=1&type=norm", "street"=>"Kluuvikatu 5", "city"=>"Helsinki", "state"=>nil, "zip"=>"00100", "country"=>"Finland", "phone"=>"+358 10 766 35", "overall"=>"67.499925", "imagecount"=>"1"}, {"id"=>"6919", "name"=>"Suomenlinnan Panimo", "status"=>"Brewpub", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=6919", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=6919&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=6919&d=1&type=norm", "street"=>"Rantakasarmi", "city"=>"Helsinki", "state"=>nil, "zip"=>"00190", "country"=>"Finland", "phone"=>"+358 9 228 5030", "overall"=>"69.166625", "imagecount"=>"0"}, {"id"=>"12408", "name"=>"St. Urho's Pub", "status"=>"Beer Bar", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=12408", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=12408&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=12408&d=1&type=norm", "street"=>"Museokatu 10", "city"=>"Helsinki", "state"=>nil, "zip"=>"00100", "country"=>"Finland", "phone"=>"+358 9 5807 7222", "overall"=>"95", "imagecount"=>"0"}, {"id"=>"12409", "name"=>"Kaisla", "status"=>"Beer Bar", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=12409", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=12409&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=12409&d=1&type=norm", "street"=>"Vilhonkatu 4", "city"=>"Helsinki", "state"=>nil, "zip"=>"00100", "country"=>"Finland", "phone"=>"+358 10 76 63850", "overall"=>"83.3334", "imagecount"=>"0"}, {"id"=>"12410", "name"=>"Pikkulintu", "status"=>"Beer Bar", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=12410", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=12410&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=12410&d=1&type=norm", "street"=>"Klaavuntie 11", "city"=>"Helsinki", "state"=>nil, "zip"=>"00910", "country"=>"Finland", "phone"=>"+358 9 321 5040", "overall"=>"91.6667", "imagecount"=>"0"}, {"id"=>"18418", "name"=>"Bryggeri Helsinki", "status"=>"Brewpub", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=18418", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=18418&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=18418&d=1&type=norm", "street"=>"Sofiankatu 2", "city"=>"Helsinki", "state"=>nil, "zip"=>"FI-00170", "country"=>"Finland", "phone"=>"010 235 2500", "overall"=>"0", "imagecount"=>"0"}, {"id"=>"18844", "name"=>"Stadin Panimo", "status"=>"Brewery", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=18844", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=18844&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=18844&d=1&type=norm", "street"=>"Kaasutehtaankatu 1, rakennus 6", "city"=>"Helsinki", "state"=>nil, "zip"=>"00540", "country"=>"Finland", "phone"=>"09 170512", "overall"=>"0", "imagecount"=>"0"}, {"id"=>"18855", "name"=>"Panimoravintola Bruuveri", "status"=>"Brewpub", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=18855", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=18855&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=18855&d=1&type=norm", "street"=>"Fredrikinkatu 63AB", "city"=>"Helsinki", "state"=>nil, "zip"=>"00100", "country"=>"Finland", "phone"=>"09 685 66 88", "overall"=>"0", "imagecount"=>"0"}]}}
2.2.1 :008 >
```

Vaikka palvelin siis palauttaa vastauksensa XML-muodossa, parsii HTTParty-gem vastauksen ja mahdollistaa sen käsittelyn suoraan miellyttävämmässä muodossa Rubyn hashinä.

Kutsun palauttamat ravintolat sisältävä taulukko saadaan seuraavasti:

```ruby
2.2.1 :013 > places = response.parsed_response['bmp_locations']['location']
2.2.1 :014 > places.size => 9
```

Helsingistä tunnetaan siis 9 paikkaa. Tutkitaan ensimmäistä:

```ruby
2.2.1 :015 > places.first
 => {"id"=>"6742", "name"=>"Pullman Bar", "status"=>"Beer Bar", "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=6742", "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=6742&d=5", "blogmap"=>"http://beermapping.com/maps/blogproxy.php?locid=6742&d=1&type=norm", "street"=>"Kaivokatu 1", "city"=>"Helsinki", "state"=>nil, "zip"=>"00100", "country"=>"Finland", "phone"=>"+358 9 0307 22", "overall"=>"72.500025", "imagecount"=>"0"}
 2.2.1 :016 > places.first.keys
 => ["id", "name", "status", "reviewlink", "proxylink", "blogmap", "street", "city", "state", "zip", "country", "phone", "overall", "imagecount"]
2.2.1 :017 >
```

Jälkimmäinen komento <code>places.first.keys</code> kertoo mitä kenttiä ravintoloihin liittyy.

Hieman monimutkaisempia hasheja tutkiessa kannattaa huomata, että Rails tarjoaa komennon <code>pp</code>, jonka avulla hash on mahdollista tulostaa ihmisystävällisemmin muotoiltuna:

```ruby
2.2.1 :016 > pp places.first
{"id"=>"6742",
 "name"=>"Pullman Bar",
 "status"=>"Beer Bar",
 "reviewlink"=>"http://beermapping.com/maps/reviews/reviews.php?locid=6742",
 "proxylink"=>"http://beermapping.com/maps/proxymaps.php?locid=6742&d=5",
 "blogmap"=>
  "http://beermapping.com/maps/blogproxy.php?locid=6742&d=1&type=norm",
 "street"=>"Kaivokatu 1",
 "city"=>"Helsinki",
 "state"=>nil,
 "zip"=>"00100",
 "country"=>"Finland",
 "phone"=>"+358 9 0307 22",
 "overall"=>"72.500025",
 "imagecount"=>"0"}
```

Luodaan panimoiden esittämiseen oma olio, kutsuttakoon sitä nimellä <code>Place</code>. Sijoitetaan luokka models-hakemistoon.

```ruby
class Place
  include ActiveModel::Model

  attr_accessor :id, :name, :status, :reviewlink, :proxylink, :blogmap, :street, :city, :state, :zip, :country, :phone, :overall, :imagecount
end
```

Koska kyseessä ei ole "normaali" luokan <code>ActiveRecord::Base</code> perivä luokka, joudumme määrittelemään metodin <code>attr_accessor</code> avulla olion attribuutit. Metodi luo jokaista parametrina olevaa symbolia kohti "getterin ja setterin", eli metodit attribuutin arvon lukemista ja päivittämistä varten.

Olioon on määritelty attribuutti kaikille beermappingin yhtä ravintolaa kohti palauttamille kentille.

Luokkaan on sisällytetty moduuli <code>ActiveModel::Model</code> (ks. http://api.rubyonrails.org/classes/ActiveModel/Model.html), joka mahdollistaa mm. konstruktorissa kaikkien attribuuttien alustamisen suoraan API:n palauttaman hashin perusteella. Eli voimme luoda API:n palauttamasta datasta Place-olioita seuraavasti:

```ruby
2.2.1 :019 > baari = Place.new places.first
 => #<Place:0x000001035a2040 @id="6742", @name="Pullman Bar", @status="Beer Bar", @reviewlink="http://beermapping.com/maps/reviews/reviews.php?locid=6742", @proxylink="http://beermapping.com/maps/proxymaps.php?locid=6742&d=5", @blogmap="http://beermapping.com/maps/blogproxy.php?locid=6742&d=1&type=norm", @street="Kaivokatu 1", @city="Helsinki", @state=nil, @zip="00100", @country="Finland", @phone="+358 9 0307 22", @overall="72.500025", @imagecount="0">
2.2.1 :020 > baari.name
 => "Pullman Bar"
2.2.1 :021 > baari.street
 => "Kaivokatu 1"
2.2.1 :022 >
```

Kirjoitetaan sitten kontrolleriin alustava koodi. Kovakoodataan etsinnän tapahtuvan aluksi Helsingistä ja luodaan ainoastaan ensimmäisestä löydetystä paikasta Place-olio:

```ruby
class PlacesController < ApplicationController
  def index
  end

  def search
    api_key = "96ce1942872335547853a0bb3b0c24db"
    url = "http://beermapping.com/webservice/loccity/#{api_key}/"
    # tai vaihtoehtoisesti
    # url = 'http://stark-oasis-9187.herokuapp.com/api/'

    response = HTTParty.get "#{url}helsinki"
    places_from_api = response.parsed_response["bmp_locations"]["location"]
    @places = [ Place.new(places_from_api.first) ]

    render :index
  end
end
```

Muokataan app/views/places/index.html.erb:tä siten, että se näyttää löydetyt ravintolat

```erb
<h1>Beer places search</h1>

<%= form_tag places_path do %>
  city <%= text_field_tag :city, params[:city] %>
  <%= submit_tag "Search" %>
<% end %>

<% if @places %>
  <ul>
    <% @places.each do |place| %>
      <li><%=place.name %></li>
    <% end %>
  </ul>
<% end %>
```

Koodi vaikuttaa toimivalta (huom. joudut uudelleenkäynnistämään Rails serverin jotta HTTParty-gem tulee ohjelman käyttöön).

Laajennetaan sitten koodi näyttämään kaikki panimot ja käyttämään lomakkeelta tulevaa parametria haettavana paikkakuntana:

```ruby
  def search
    api_key = "96ce1942872335547853a0bb3b0c24db"
    url = "http://beermapping.com/webservice/loccity/#{api_key}/"
    response = HTTParty.get "#{url}#{params[:city]}"

    @places = response.parsed_response["bmp_locations"]["location"].map do | place |
      Place.new(place)
    end

    render :index
  end
```

Sovellus toimii muuten, mutta jos haetulla paikkakunnalla ei ole ravintoloita, tapahtuu virhe.

Käyttämällä debuggeria huomaamme, että näissä tapauksissa API:n palauttama paikkojen lista näyttää seuraavalta:

```ruby
{"id"=>nil, "name"=>nil, "status"=>nil, "reviewlink"=>nil, "proxylink"=>nil, "blogmap"=>nil, "street"=>nil, "city"=>nil, "state"=>nil, "zip"=>nil, "country"=>nil, "phone"=>nil, "overall"=>nil, "imagecount"=>nil}
```

Eli paluuarvona on hash. Jos taas haku löytää oluita paluuarvo on taulukko, jonka sisällä on hashejä. Virittelemme koodia ottamaan tämän huomioon. Koodi huomioi myös mahdollisuuden, jossa API palauttaa hashin, joka ei kuitenkaan vastaa olemassaolematonta paikkaa. Näin käy jos haetulla paikkakunnalla on vain yksi ravintola.

```ruby
class PlacesController < ApplicationController
  def index
  end

  def search
    api_key = "96ce1942872335547853a0bb3b0c24db"
    url = "http://beermapping.com/webservice/loccity/#{api_key}/"
    response = HTTParty.get "#{url}#{params[:city]}"
    places_from_api = response.parsed_response["bmp_locations"]["location"]

    if places_from_api.is_a?(Hash) and places_from_api['id'].nil?
      redirect_to places_path, :notice => "No places in #{params[:city]}"
    else
      places_from_api = [places_from_api] if places_from_api.is_a?(Hash)
      @places = places_from_api.map do | location |
        Place.new(location)
      end
      render :index
    end
  end

end
```

Koodi on tällä hetkellä rumaa, mutta parantelemme sitä hetken kuluttua. Näytetään baareista enemmän tietoja sivulla. Määritellään näytettävät kentät Place-luokan staattisena metodina:

```ruby
class Place
  include ActiveModel::Model
  attr_accessor :id, :name, :status, :reviewlink, :proxylink, :blogmap, :street, :city, :state, :zip, :country, :phone, :overall, :imagecount

  def self.rendered_fields
    [:id, :name, :status, :street, :city, :zip, :country, :overall ]
  end
end
```

index.html.erb:n paranneltu koodi seuraavassa:

```erb
<p id="notice"><%= notice %></p>

<%= form_tag places_path do %>
  city <%= text_field_tag :city, params[:city] %>
  <%= submit_tag "Search" %>
<% end %>

<% if @places %>
  <table>
    <thead>
      <% Place.rendered_fields.each do |f| %>
        <td><%=f %></td>
      <% end %>
    </thead>
    <% @places.each do |place| %>
      <tr>
        <% Place.rendered_fields.each do |f| %>
          <td><%= place.send(f) %></td>
        <% end %>
      </tr>
    <% end %>
  </table>
<% end %>
```

Sovelluksessamme on vielä pieni ongelma Jos yritämme etsiä New Yorkin olutravintoloita on seurauksena virhe. Välilyönnit on korvattava URL:ssä koodilla %20. Korvaamista ei kannata tehdä itse 'käsin', välilyönti ei nimittäin ole ainoa merkki joka on koodattava URL:iin. Kuten arvata saattaa, on Railsissa tarjolla tarkoitusta varten valmis metodi <code>ERB::Util.url_encode</code>. Kokeillaan metodia konsolista:

```ruby
2.2.1 :022 > ERB::Util.url_encode("St John's")
 => "St%20John%27s"
2.2.1 :023 >
```

Tehdään nyt muutos koodiin korvaamalla HTTP GET -pyynnön tekevä rivi seuraavalla:

```ruby
    response = HTTParty.get "#{url}#{ERB::Util.url_encode(params[:city])}"
```

> ## Tehtävä 1
>
> Tee edelläoleva koodi ohjelmaasi. Lisää myös navigointipalkkiin linkki olutpaikkojen hakusivulle

## Places-kontrollerin refaktorointi

Railsissa kontrollereiden ei tulisi sisältää sovelluslogiikkaa. Ulkopuoleisen API:n käyttö onkin syytä eristää omaksi luokakseen. Sijoitetaan luokka lib-hakemistoon (tiedostoon beermapping_api.rb):

```ruby
class BeermappingApi
  def self.places_in(city)
    url = "http://beermapping.com/webservice/loccity/#{key}/"

    response = HTTParty.get "#{url}#{ERB::Util.url_encode(city)}"
    places = response.parsed_response["bmp_locations"]["location"]

    return [] if places.is_a?(Hash) and places['id'].nil?

    places = [places] if places.is_a?(Hash)
    places.map do | place |
      Place.new(place)
    end
  end

  def self.key
    "96ce1942872335547853a0bb3b0c24db"
  end
end
```

Luokka siis määrittelee stattisen metodin, joka palauttaa taulukon parametrina määritellystä kaupungista löydetyistä olutpaikoista. Jos paikkoja ei löydy, on taulukko tyhjä. API:n eristävä luokka ei ole vielä viimeiseen asti hiotussa muodossa, sillä emme vielä täysin tiedä mitä muita metodeja tarvitsemme.

**HUOM:** jos et tehnyt [viikon 2 tehtävää 15](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#teht%C3%A4v%C3%A4-15) tai sijoitit tehtävässä määritellyn moduulin hakemistoon _app/models/concerns_, lisää tiedostoon _config/application.rb_ luokan <code>Application</code> määrittelyn sisälle rivi <code>config.autoload_paths += Dir["#{Rails.root}/lib"]</code>, jotta Rails lataisi lib-hakemistoon sijoitetun koodin sovelluksen luokkien käyttöön. Huomaa, että joudut uudelleenkäynnistämään Rails-palvelimen muutoksen jälkeen.

Kontrollerista tulee nyt siisti:

```ruby
class PlacesController < ApplicationController
  def index
  end

  def search
    @places = BeermappingApi.places_in(params[:city])
    if @places.empty?
      redirect_to places_path, notice: "No locations in #{params[:city]}"
    else
      render :index
    end
  end
end
```

## Olutpaikkojen etsimistoiminnon testaaminen

Tehdään seuraavaksi Rspec-testejä toteuttamallemme toiminnallisuudelle. Uusi toiminnallisuutemme käyttää siis hyväkseen ulkoista palvelua. Testit on kuitenkin syytä kirjoittaa siten, ettei ulkoista palvelua käytetä. Onneksi ulkoisen rajapinnan korvaaminen stub-komponentilla on Railsissa helppoa.

Päätämme jakaa testit kahteen osaan. Korvaamme ensin ulkoisen rajapinnan kapseloivan luokan <code>BeermappingApi</code> toiminnallisuuden stubien avulla kovakoodatulla toiminnallisuudella. Testi siis testaa, toimiiko places-sivu oikein olettaen, että <code>BeermappingApi</code>-komponentti toimii.

Testaamme sitten erikseen Rspecillä kirjoitettavilla yksikkötesteillä <code>BeermappingApi</code>-komponentin toiminnan.

Aloitetaan siis web-sivun places-toiminnallisuuden testaamisesta. Tehdään testiä varten tiedosto /spec/features/places_spec.rb

```ruby
require 'rails_helper'

describe "Places" do
  it "if one is returned by the API, it is shown at the page" do
    allow(BeermappingApi).to receive(:places_in).with("kumpula").and_return(
      [ Place.new( name:"Oljenkorsi", id: 1 ) ]
    )

    visit places_path
    fill_in('city', with: 'kumpula')
    click_button "Search"

    expect(page).to have_content "Oljenkorsi"
  end
end
```

Testi alkaa heti mielenkiintoisella komennolla:

```ruby
    allow(BeermappingApi).to receive(:places_in).with("kumpula").and_return(
      [ Place.new( name:"Oljenkorsi", id: 1 ) ]
    )
```

Komento "kovakoodaa" luokan <code>BeermappingApi</code> metodin <code>places_in</code> vastaukseksi määritellyn yhden Place-olion sisältävän taulukon, jos metodia kutsutaan parametrilla "kumpula".

Kun nyt testissä tehdään HTTP-pyyntö places-kontrollerille, ja kontrolleri kutsuu API:n metodia <code>places_in</code>, metodin todellisen koodin suorittamisen sijaan places-kontrollerille palautetaankin kovakoodattu vastaus.

Jos törmäät testejä suorittaessasi virheeseen

```ruby
mbp-18:ratebeer mluukkai$ rspec spec/features/places_spec.rb
/Users/mluukkai/.rbenv/versions/2.0.0-p247/lib/ruby/gems/2.0.0/gems/activerecord-4.0.2/lib/active_record/migration.rb:379:in `check_pending!': Migrations are pending; run 'bin/rake db:migrate RAILS_ENV=test' to resolve this issue. (ActiveRecord::PendingMigrationError)
…
```

Syynä tälle on se, että testiympäristössä ei ole suoritettu kaikkia tietokantamigraatioita. Ongelma korjaantuu komennolla <code>rake db:test:prepare</code>. Jos törmäät johonkin gemien versioihin liittyvään virheeseen (näin kävi itselläni kertaalleen), suorita <code>bundle update</code>.

> ## Tehtävä 2
>
> Laajenna testiä kattamaan seuraavat tapaukset:
> * jos API palauttaa useita olutpaikkoja, kaikki näistä näytetään sivulla
> * jos API ei löydä paikkakunnalta yhtään olutpaikkaa (eli paluuarvo on tyhjä taulukko), sivulla näytetään ilmoitus "No locations in _etsitty paikka_"

Siirrytään sitten luokan <code>BeermappingApi</code> testaamiseen. Luokka siis tekee HTTP GET -pyynnön HTTParty-kirjaston avulla Beermapping-palveluun. Voisimme edellisen esimerkin tapaan stubata HTTPartyn get-metodin. Tämän on kuitenkin hieman ikävää, sillä metodi palauttaa <code>HTTPartyResponse</code>-olion ja sellaisen muodostaminen stubauksen yhteydessä käsin ei välttämättä ole kovin mukavaa.

Parempi vaihtoehto onkin käyttää gemiä _webmock_ https://github.com/bblimke/webmock/ sillä se mahdollistaa stubauksen HTTPartyn käyttämän kirjaston tasolla.

Otetaan gem käyttöön lisäämällä Gemfilen **test-scopeen** rivi <code>gem 'webmock'</code>;

```ruby
group :test do
    # ...
    gem 'webmock'
end
```

**HUOM: webmock on määriteltävä _ainoastaan_ test-scopeen, muuten se estää kaikki sovelluksen tekemät HTTP-pyynnöt!**

Suoritetaan <code>bundle install</code>.

Tiedostoon ```spec/rails_helper.rb``` pitää vielä lisätä rivi:

```ruby
require 'webmock/rspec'
```

Webmock-kirjaston käyttö on melko helppoa. Esim. seuraava komento stubaa _jokaiseen_ URLiin (määritelty regexpillä <code>/.*/</code>) tulevan GET-pyynnön palauttamaan 'Lapin kullan' tiedot XML-muodossa:

```ruby
stub_request(:get, /.*/).to_return(body:"<beer><name>Lapin kulta</name><brewery>Hartwall</brewery></beer>", headers:{ 'Content-Type' => "text/xml" })
```

Eli jos kutsuisimme komennon tehtyämme esim. <code>HTTParty.get("http://www.google.com")</code> olisi vastauksena

```xml
<beer>
  <name>Lapin kulta</name>
  <brewery>Hartwall</brewery>
</beer>
```

Tarvitsemme siis testiämme varten sopivan "kovakoodatun" datan, joka kuvaa Beermapping-palvelun HTTP GET -pyynnön palauttamaa XML:ää.

Eräs tapa testisyötteen generointiin on kysyä se rajapinnalta itseltään, eli tehdään komentoriviltä <code>curl</code>-komennolla HTTP GET -pyyntö:

```ruby
mbp-18:ratebeer mluukkai$ curl http://beermapping.com/webservice/loccity/96ce1942872335547853a0bb3b0c24db/espoo
<?xml version='1.0' encoding='utf-8' ?><bmp_locations><location><id>12411</id><name>Gallows Bird</name><status>Brewery</status><reviewlink>http://beermapping.com/maps/reviews/reviews.php?locid=12411</reviewlink><proxylink>http://beermapping.com/maps/proxymaps.php?locid=12411&amp;d=5</proxylink><blogmap>http://beermapping.com/maps/blogproxy.php?locid=12411&amp;d=1&amp;type=norm</blogmap><street>Merituulentie 30</street><city>Espoo</city><state></state><zip>02200</zip><country>Finland</country><phone>+358 9 412 3253</phone><overall>91.66665</overall><imagecount>0</imagecount></location></bmp_locations>
```

Nyt voimme copypastata HTTP-pyynnön palauttaman XML-muodossa olevan tiedon testiimme. Jotta saamme XML:n varmasti oikein sijoitetuksi merkkijonoon, käytämme hieman erikoista syntaksia
ks. http://blog.jayfields.com/2006/12/ruby-multiline-strings-here-doc-or.html jossa merkkijono sijoitetaan merkkien <code><<-END_OF_STRING</code> ja <code>END_OF_STRING</code> väliin.

Seuraavassa tiedostoon spec/lib/beermapping_api_spec.rb  sijoitettava testikoodi (päätimme sijoittaa koodin alihakemistoon lib koska testin kohde on lib-hakemistossa oleva apuluokka):

```ruby
require 'rails_helper'

describe "BeermappingApi" do
  it "When HTTP GET returns one entry, it is parsed and returned" do

    canned_answer = <<-END_OF_STRING
<?xml version='1.0' encoding='utf-8' ?><bmp_locations><location><id>12411</id><name>Gallows Bird</name><status>Brewery</status><reviewlink>http://beermapping.com/maps/reviews/reviews.php?locid=12411</reviewlink><proxylink>http://beermapping.com/maps/proxymaps.php?locid=12411&amp;d=5</proxylink><blogmap>http://beermapping.com/maps/blogproxy.php?locid=12411&amp;d=1&amp;type=norm</blogmap><street>Merituulentie 30</street><city>Espoo</city><state></state><zip>02200</zip><country>Finland</country><phone>+358 9 412 3253</phone><overall>91.66665</overall><imagecount>0</imagecount></location></bmp_locations>
    END_OF_STRING

    stub_request(:get, /.*espoo/).to_return(body: canned_answer, headers: { 'Content-Type' => "text/xml" })

    places = BeermappingApi.places_in("espoo")

    expect(places.size).to eq(1)
    place = places.first
    expect(place.name).to eq("Gallows Bird")
    expect(place.street).to eq("Merituulentie 30")
  end

end
```

Testi siis ensin määrittelee, että URL:iin joka loppuu merkkijonoon "espoo" (määritelty regexpillä <code>/.*espoo/</code>) kohdistuvan  HTTP GET -kutsun palauttamaan kovakoodatun XML:n, HTTP-kutsun palauttamaan headeriin määritellään, että palautettu tieto on XML-muodossa. Ilman tätä määritystä HTTParty-kirjasto ei osaa parsia HTTP-pyynnön palauttamaa dataa oikein.

Itse testi tapahtuu suoraviivaisesti tarkastelemalla BeermappingApi:n metodin <code>places_in</code> palauttamaa taulukkoa.

*Huom:* stubasimme testissä ainoastaan merkkijonoon "espoo" loppuviin URL:eihin (<code>/.*espoo/</code>) kohdistuvat HTTP GET -kutsut. Jos testin suoritus aiheuttaa jonkin muunlaisen HTTP-kutsun, huomauttaa testi tästä:

```ruby
) BeermappingApi When HTTP GET returns no entries, an empty array is returned
     Failure/Error: places = BeermappingApi.places_in("kumpula")
     WebMock::NetConnectNotAllowedError:
       Real HTTP connections are disabled. Unregistered request: GET http://beermapping.com/webservice/loccity/96ce1942872335547853a0bb3b0c24db/kumpula

       You can stub this request with the following snippet:

       stub_request(:get, "http://beermapping.com/webservice/loccity/96ce1942872335547853a0bb3b0c24db/kumpula").
         to_return(:status => 200, :body => "", :headers => {})
```

Kuten virheilmoitus antaa ymmärtää, voidaan komennon <code>stub_request</code> avulla stubata myös merkkijonona määriteltyyn yksittäiseen URL:iin kohdistuva HTTP-kutsu. Sama testi voi myös sisältää useita <code>stub_request</code>-kutsuja, jotka kaikki määrittelevät eri URLeihin kohdistuvien pyyntöjen vastaukset.

> ## Tehtävä 3
>
> Laajenna testejä kattamaan seuraavat tapaukset
> * HTTP GET ei palauta yhtään paikkaa, eli tällöin metodin <code>places_in</code> tulee palauttaa tyhjä taulukko
> * HTTP GET palauttaa useita paikkoja, eli tällöin metodin <code>places_in</code> tulee palauttaa kaikki HTTP-kutsun XML-muodossa palauttamat ravintolat taulukollisena Place-olioita
>
> Stubatut vastaukset kannattaa jälleen muodostaa curl-komennon avulla API:n tehdyillä kyselyillä

Erilaisten lavastekomponenttien tekeminen eli metodien ja kokonaisten olioiden stubaus sekä mockaus on hyvin laaja aihe. Voit lukea aiheesta Rspeciin liittyen seuraavasta http://rubydoc.info/gems/rspec-mocks/

Nimityksiä stub- ja mock-olio tai "stubaaminen ja mockaaminen" käytetään usein varsin huolettomasti. Onneksi Rails-yhteisö käyttää termejä oikein. Lyhyesti ilmaistuna stubit ovat olioita, joihin on kovakoodattu valmiiksi metodien vastauksia. Mockit taas toimivat myös stubien tapaan kovakoodattujen vastausten antajana, mutta sen lisäksi mockien avulla voidaan määritellä odotuksia siitä miten niiden metodeja kutsutaan. Jos testattavana olevat oliot eivät kutsu odotetulla tavalla mockien metodeja, aiheutuu tästä testivirhe.

Mockeista ja stubeista lisää esim. seuraavassa: http://martinfowler.com/articles/mocksArentStubs.html

## Suorituskyvyn optimointi

Tällä hetkellä sovelluksemme toimii siten, että se tekee kyselyn beermappingin palveluun aina kun jonkin kaupungin ravintoloita haetaan. Voisimme tehostaa sovellusta muistamalla viime aikoina suoritettuja hakuja.

Rails tarjoaa avain-arvopari-periaatteella toimivan hyvin helppokäyttöisen cachen eli välimuistin sovelluksen käyttöön. Kokeillaan konsolista:

```ruby
2.2.1 :001 > Rails.cache.write "avain", "arvo"
 => true
2.2.1 :002 > Rails.cache.read "avain"
 => "arvo"
2.2.1 :003 > Rails.cache.read "kumpula"
 => nil
2.2.1 :004 > Rails.cache.write "kumpula", Place.new(name:"Oljenkorsi")
 => true
2.2.1 :005 > Rails.cache.read "kumpula"
 => #<Place:0x00000104628608 @name="Oljenkorsi">
```

Cacheen voi tallettaa melkein mitä vaan. Ja rajapinta on todella yksinkertainen, ks. http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

Metodien <code>read</code> ja <code>write</code> lisäksi Railsin cache tarjoaa joihinkin tilanteisiin todella hyvin sopivan metodin <code>fetch</code>. Metodille annetaan välimuistista haettavan avaimen lisäksi koodilohko, joka suoritetaan ja talletetaan avaimen arvoksi _jos_ avaimella ei ole jo talletettuna arvoa ennestään.

Esim. komento <code>Rails.cache.fetch("first_user") { User.first }</code> hakee välimuistista avaimella *first_user* talletutun olion. Jos avaimelle ei ole vielä talletettu arvoa, suortetaan komento <code>User.first</code>, ja talletetaan sen palauttama olio avaimen arvoksi. Seuraavassa esimerkki:


```ruby
2.2.1 :006 > Rails.cache.fetch("first_user") { User.first }
  User Load (0.7ms)  SELECT  "users".* FROM "users"   ORDER BY "users"."id" ASC LIMIT 1
 => #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 18:37:23", password_digest: "$2a$10$A6KEp02KHLMrpEkij9zcKu/wOjD4h4lsgC1drWwIy2O...">
2.2.1 :007 > Rails.cache.fetch("first_user") { User.first }
 => #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 18:37:23", password_digest: "$2a$10$A6KEp02KHLMrpEkij9zcKu/wOjD4h4lsgC1drWwIy2O...">
2.2.1 :008 >
```

Ensimmäinen metodikutsu siis aiheuttaa tietokantahaun ja tallettaa olion välimuistiin. Seuraava kutsu saa avainta vastaavan olion suoraan välimuistista.

Oletusarvoisesti Railsin cache tallettaa avain-arvo-parit tiedostojärjestelmään. Cachen käyttämä talletustapa on kuitenkin konfiguroitavissa, ks. http://guides.rubyonrails.org/caching_with_rails.html#cache-stores

Tuotantokäytössä välimuistin datan tallettaminen tiedostojärjestelmään ei ole suorituskyvyn kannalta optimaalista. Parempi ratkaisu onkin esim. [Memcached](http://memcached.org/), ks. tarkemmin esim. https://devcenter.heroku.com/articles/building-a-rails-3-application-with-memcache

**Huom:** koska testimme alkavat pian testaamaan Rails.cachea hyväksikäyttävää koodia, kannattaa cache konfiguroida käyttämään testien aikana talletuspaikkanaan tiedostojärjestelmän sijaan __keskusmuistia__. Tämä tapahtuu lisäämällä tiedostoon _config/environments/test.rb_ rivi

```ruby
config.cache_store = :memory_store
```

Jos et tee muutosta, cachea käyttävät testit eivät toimi Travisissa, sillä Travisin käytössä on readonly-tiedostojärjestelmä.

Viritellään luokkaa <code>BeermappingApi</code> siten, että se tallettaa tehtyjen kyselyjen tulokset välimuistiin. Jos kysely kohdistuu jo välimuistissa olevaan kaupunkiin, palautetaan tulos välimuistista.

```ruby
class BeermappingApi
  def self.places_in(city)
    city = city.downcase
    Rails.cache.fetch(city) { fetch_places_in(city) }
  end

  private

  def self.fetch_places_in(city)
    url = "http://beermapping.com/webservice/loccity/#{key}/"

    response = HTTParty.get "#{url}#{ERB::Util.url_encode(city)}"
    places = response.parsed_response["bmp_locations"]["location"]

    return [] if places.is_a?(Hash) and places['id'].nil?

    places = [places] if places.is_a?(Hash)
    places.map do | place |
      Place.new(place)
    end
  end

  def self.key
    "96ce1942872335547853a0bb3b0c24db"
  end
end
```

Avaimena käytetään pienillä kirjaimilla kirjoitettua kaupungin nimeä.
Käytössä on nyt metodi <code>fetch</code>, joka palauttaa välimuistissa olevat tiedot kaupungin olutravintoloista _jos_ ne löytyvät jo välimuistista. Jos välimuistissa ei vielä ole kapungin ravintoloiden tietoja, suoritetaan toisena parametrina oleva koodi <code>fetch_places_in(city)</code> joka hakee tiedot ja tallettaa ne välimuistiin.

Jos teemme nyt haun kaksi kertaa peräkkäin esim. New Yorkin oluista, huomaamme, että toisella kerralla vastaus tulee huomattavasti nopeammin.

Pääsemme sovelluksen välimuistiin tallettamaan dataan käsiksi myös konsolista:

```ruby
2.2.1 :010 > Rails.cache.read("helsinki").map(&:name)
 => ["Pullman Bar", "Belge", "Suomenlinnan Panimo", "St. Urho's Pub", "Kaisla", "Pikkulintu", "Bryggeri Helsinki", "Stadin Panimo", "Panimoravintola Bruuveri"]
2.2.1 :011 >
```

Konsolista käsin on myös mahdollista tarvittaessa poistaa tietylle avaimelle talletettu data:

```ruby
2.2.1 :011 > Rails.cache.delete("helsinki")
 => true
2.2.1 :012 > Rails.cache.read("helsinki")
 => nil
2.2.1 :013 >
```

## Vanhentunut data

Välimuistin käytön ongelmana on mahdollinen tiedon epäajantasaisuus. Eli jos joku lisää ravintoloita beermappingin sivuille, välimuistissamme säilyy edelleen vanha data. Jollain tavalla tulisi siis huolehtia, että välimuistiin ei pääse jäämään liian vanhaa dataa.

Yksi ratkaisu olisi aika ajoin nollata välimuistissa oleva data komennolla:

    Rails.cache.clear

Tilanteeseemme paremmin sopiva ratkaisu on määritellä välimuistiin talletettavalle datalle enimmäiselinikä.

> ## Tehtävä 4
>
> ### tämä ei ole viikon tärkein tehtävä, joten älä jää jumittamaan tähän jos kohtaat ongelmia
>
> Määrittele välimuistiin talletettaville ravintolatiedoille enimmäiselinikä, esim. 1 viikko. Testatessasi tehtävän toimintaa, kannattaa kuitenkin käyttää pienempää elinikää, esim. yhtä minuuttia.
>
> Tehtävän tekeminen ei edellytä kovin suuria muutoksia koodiisi, oikeastaan muutoksia tarvitaan vain _yhdelle_ riville. Tarvittavat vihjeet löydät sivulta http://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-store Ajan käsittelyssä auttaa http://guides.rubyonrails.org/active_support_core_extensions.html#time
>
> **Huom:** kuten aina, nytkin kannattaa testailla enimmäiseliniän asettamisen toimivuutta konsolista käsin!
>
> **Huom2:** jos saat välimuistin sekaisin, muista <code>Rails.cache.clear</code> ja <code>Rails.cache.delete avain</code>

## Testit ja cache

Tehtävässä 3 teimme Webmock-gemin avulla testejä luokalle <code>BeermappingApi</code>. On syytä huomioida, että välimuisti vaikuttaa myös testaamiseen, ja olisikin kenties parasta testata erikseen tilanne, jossa data ei löydy välimuistista (cache miss) sekä tilanne, jossa data on jo välimuistissa (cache hit):

```ruby
require 'rails_helper'

describe "BeermappingApi" do
  describe "in case of cache miss" do

    before :each do
      Rails.cache.clear
    end

    it "When HTTP GET returns one entry, it is parsed and returned" do
      canned_answer = <<-END_OF_STRING
<?xml version='1.0' encoding='utf-8' ?><bmp_locations><location><id>12411</id><name>Gallows Bird</name><status>Brewery</status><reviewlink>http://beermapping.com/maps/reviews/reviews.php?locid=12411</reviewlink><proxylink>http://beermapping.com/maps/proxymaps.php?locid=12411&amp;d=5</proxylink><blogmap>http://beermapping.com/maps/blogproxy.php?locid=12411&amp;d=1&amp;type=norm</blogmap><street>Merituulentie 30</street><city>Espoo</city><state></state><zip>02200</zip><country>Finland</country><phone>+358 9 412 3253</phone><overall>91.66665</overall><imagecount>0</imagecount></location></bmp_locations>
      END_OF_STRING

      stub_request(:get, /.*espoo/).to_return(body: canned_answer, headers: {'Content-Type' => "text/xml"})

      places = BeermappingApi.places_in("espoo")

      expect(places.size).to eq(1)
      place = places.first
      expect(place.name).to eq("Gallows Bird")
      expect(place.street).to eq("Merituulentie 30")
    end

  end

  describe "in case of cache hit" do

    it "When one entry in cache, it is returned" do
      canned_answer = <<-END_OF_STRING
<?xml version='1.0' encoding='utf-8' ?><bmp_locations><location><id>13307</id><name>O'Connell's Irish Bar</name><status>Beer Bar</status><reviewlink>http://beermapping.com/maps/reviews/reviews.php?locid=13307</reviewlink><proxylink>http://beermapping.com/maps/proxymaps.php?locid=13307&amp;d=5</proxylink><blogmap>http://beermapping.com/maps/blogproxy.php?locid=13307&amp;d=1&amp;type=norm</blogmap><street>Rautatienkatu 24</street><city>Tampere</city><state></state><zip>33100</zip><country>Finland</country><phone>35832227032</phone><overall>0</overall><imagecount>0</imagecount></location></bmp_locations>
      END_OF_STRING

      stub_request(:get, /.*espoo/).to_return(body: canned_answer, headers: {'Content-Type' => "text/xml"})

      # ensure that data found in cache
      BeermappingApi.places_in("espoo")

      places = BeermappingApi.places_in("espoo")

      expect(places.size).to eq(1)
      place = places.first
      expect(place.name).to eq("O'Connell's Irish Bar")
      expect(place.street).to eq("Rautatienkatu 24")
    end
  end
end


```

Testi sisältää nyt paljon toisteisuutta ja kaipaisi refaktorointia, mutta menemme kuitenkin eteenpäin.

**Vielä uusi huomautus asiasta:** koska testaamme Rails.cachea hyväksikäyttävää koodia, kannattaa cache konfiguroida käyttämään testien aikana talletuspaikkanaan tiedostojärjestelmän sijaan __keskusmuistia__. Tämä tapahtuu lisäämällä tiedostoon _config/environments/test.rb_ rivi

```ruby
config.cache_store = :memory_store
```

Jos et tee muutosta, cachea käyttävät testit eivät toimi Travisissa, sillä Travisin käytössä on readonly-tiedostojärjestelmä.

## Sovelluskohtaisen datan tallentaminen

Koodissamme API-key on nyt kirjoitettu sovelluksen koodiin. Tämä ei tietenkään ole järkevää. Railsissa on useita mahdollisuuksia konfiguraatiotiedon tallentamiseen, ks. esim. http://quickleft.com/blog/simple-rails-app-configuration-settings

Ehkä paras vaihtoehto suhteellisen yksinkertaisen sovelluskohtaisen datan tallettamiseen ovat ympäristömuuttujat. Esimerkki seuraavassa:

Asetetaan ensin komentoriviltä ympäristömuuttujalle <code>APIKEY</code>

```ruby
mbp-18:ratebeer mluukkai$ export APIKEY="96ce1942872335547853a0bb3b0c24db"
```

Rails-sovellus pääsee ympäristömuuttujiin käsiksi hash-tyyppisen muuttujan <code>ENV</code> kautta:

```ruby
2.2.1 :001 > ENV['APIKEY']
 => "96ce1942872335547853a0bb3b0c24db"
2.2.1 :002 >
```

Poistetaan kovakoodattu apiavain ja luetaan se ympäristömuuttujasta:

```ruby
class BeermappingApi
  # ...

  def self.key
    raise "APIKEY env variable not defined" if ENV['APIKEY'].nil?
    ENV['APIKEY']
  end
end
```

Koodiin on myös lisätty suoritettavaksi poikkeus tilanteessa, jossa apiavainta ei ole määritelty.

Ympäristömuuttujan arvon tulee siis olla määritelty jos käytät olutravintoloiden hakutoimintoa. Saat määriteltyä ympäristömuuttujan käynnistämällä sovelluksen seuraavasti:

```ruby
mbp-18:ratebeer mluukkai$export APIKEY="96ce1942872335547853a0bb3b0c24db"
mbp-18:ratebeer mluukkai$rails s
```

tai määrittelemällä ympäristömuuttujan käynnistyskomennon yhteydessä:

```ruby
mbp-18:ratebeer mluukkai$APIKEY="96ce1942872335547853a0bb3b0c24db" rails s
```

Voit myös määritellä ympäristömuuttujan arvon (export-komennolla) komentotulkin käynistyksen yhteydessä suoritettavassa tiedostossa (.zshrc, .bascrc tai .profile komentotulkista riippuen).

Ympäristömuuttujille on helppo asettaa arvo myös Herokussa, ks.
https://devcenter.heroku.com/articles/config-vars

**HUOM** Jos haluat pitää Traviksen toimintakunnossa, joudut määrittelemään ympäristömuuttujan Travis-konfiguraatioon ks.
[http://docs.travis-ci.com/user/environment-variables/](http://docs.travis-ci.com/user/environment-variables/)

## Lisäselvennys kontrollerin toiminnasta

Muutamien osalla on ollut havaittavissa hienoista epäselvyyttä kontrollereiden <code>show</code>-metodien toimintaperiaatteessa. Seuraavaakin tehtävää silmälläpitäen kerrataan asiaa hieman.

Tarkastellaan panimon kontorolleria. Yksittäisen panimon näyttämisestä vastaava kontrollerimetodi ei sisällä mitään koodia:

```ruby
  def show
  end
```

oletusarvoisesti renderöityvä näkymätemplate app/views/breweries/show.html.erb kuitenkin viittaa muuttujaan <code>@brewery</code>:

```ruby
    <h2><%= @brewery.name %>
    </h2>

    <p>
      <em>Established year:</em>
      <%= @brewery.year %>
    </p>
```

eli miten muuttuja saa arvonsa? Arvo asetetaan kontrollerissa _esifiltteriksi_ määritellyssä metodissa <code>set_brewery</code>.

```ruby
class BreweriesController < ApplicationController
  before_action :set_brewery, only: [:show, :edit, :update, :destroy]
  #...

  def set_brewery
    @brewery = Brewery.find(params[:id])
  end
end
```

kontrolleri siis määrittelee, että aina ennen metodin <code>show</code> suorittamista suoritetaan koodi

```ruby
@brewery = Brewery.find(params[:id])
```

joka lataa panimo-olion muistista ja tallettaa sen näkymää varten muuttujaan.

Kuten koodista on pääteltävissä, kontrolleri pääsee käsiksi panimon id:hen <code>params</code>-hashin kautta. Mihin tämä perustuu?

Kun katsomme sovelluksen routeja joko komennolla <code>rake routes</code> tai selaimesta (menemällä mihin tahansa epävalidiin osoitteeseen), huomaamme, että yksittäiseen panimoon liittyvä routetieto on seuraava

```ruby
brewery_path	 GET	 /breweries/:id(.:format)	 breweries#show
```

eli yksittäisen panimon URL on muotoa _breweries/42_ missä lopussa oleva luku on panimon id. Kuten polkumäärittely vihjaa, sijoitetaan panimon id <code>params</code>-hashin avaimen <code>:id</code> arvoksi.

Voisimme määritellä 'parametrillisen' polun myös käsin. Jos lisäisimme routes.rb:hen seuraavan

```ruby
   get 'panimo/:id', to: 'breweries#show'
```

pääsisi yksittäisen panimon sivulle osoitteesta http://localhost:3000/panimo/42. Osoitteen käsittelisi edelleen kontrollerin metodi <code>show</code>, joka pääsisi käsiksi id:hen tuttuun tapaan <code>params</code>-hashin kautta.

Jos taas päättäisimme käyttää jotain muuta kontrollerimetodia, ja määrittelisimme reitin seuraavasti

```ruby
   get 'panimo/:panimo_id', to: 'breweries#nayta'
```

kontrollerimetodi voisi olla esim. seuraava:

```ruby
   def nayta
     @brewery = Brewery.find(params[:panimo_id])
     render :index
   end
```

eli tällä kertaa routeissa määriteltiin, että panimon id:hen viitataan <code>params</code>-hashin avaimella <code>:panimo_id</code>.

## Ravintolan sivu

> ## Tehtävät 5-6 (vastaa kahta tehtävää)
>
> Tee sovellukselle ominaisuus, jossa ravintolan nimeä klikkaamalla avautuu oma sivu, jossa on näkyvillä ravintolan tiedot. Sisällytä sivulle (esim. iframena) myös kartta, johon on merkattu ravintolan sijainti. Huomaa, että kartan url löytyy suoraan ravintolan tiedoista. Jos haluat hifistellä, iframeja parempi vaihtoehto on [Googlen Map APIn](https://developers.google.com/maps/) käyttö.
>
> Jos näytät kartan iframessa, joudut muuttamaan kartan urlissa protokollan _http_:stä _https_:ksi jotta kartta toimisi herokussa. Paikallisesti suoritettaessa urlin protokollan tulee kuitenkin olla _http_
>
>* ravintolan urliksi kannattaa vailta Rails-konvention mukainen places/:id, routes.rb voi näyttää esim. seuraavalta:
>
>```ruby
> resources :places, only:[:index, :show]
> # mikä generoi samat polut kuin seuraavat kaksi
> # get 'places', to:'places#index'
> # get 'places/:id', to:'places#show'
>
> post 'places', to:'places#search'
> ```
>
>* HUOM: ravintolan tiedot löytyvät hieman epäsuorasti cachesta siinä vaiheessa kun ravintolan sivulle ollaan menossa. Jotta pääset tietoihin käsiksi on ravintolan id:n lisäksi "muistettava" kaupunki, josta ravintolaa etsittiin, tai edelliseksi tehdyn search-operaation tulos. Yksi tapa muistamiseen on käyttää sessiota, ks. https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko3.md#k%C3%A4ytt%C3%A4j%C3%A4-ja-sessio
>
> Toinen tapa toiminnallisuuden toteuttamiseen on sivulla http://beermapping.com/api/reference/ oleva "Locquery Service"
>
> Kokeile hajottaako ravointoloiden sivun lisääminen mitään olemassaolevaa testiä. Jos, niin voit yrittää korjata testit. Välttämätöntä se ei kuitenkaan tässä vaiheessa ole.


Tehtävän jälkeen sovelluksesi voi näyttää esim. seuraavalta:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-2.png)


## Oluen reittaus suoraan oluen sivulta

Tällä hetkellä reittaukset luodaan erilliseltä sivulta, jolta reitattava olut valitaan erillisestä valikosta. Olisi luontevampaa, jos reittauksen voisi tehdä myös suoraan kunkin oluen sivulta.

Vaihtoehtoisia toteutustapoja on useita. Tutkitaan seuraavassa ehkä helpointa ratkaisua. Käytetään <code>form_for</code>-helperiä, eli luodaan lomake pohjalla olevaa olia hyödyntäen. **BeersControllerin** metodiin show tarvitaan pieni muutos:

```ruby
  def show
    @rating = Rating.new
    @rating.beer = @beer
  end
```

Eli siltä varalta, että oluelle tehdään reittaus, luodaan näykymätemplatea varten reittausolio, joka on jo liitetty tarkasteltavaan olioon. Reittausolio on luotu new:llä eli sitä ei siis ole talletettu kantaan, huomaa, että ennen metodin <code>show</code> suorittamista on suoritettu esifiltterin avulla määritelty komento, joka hakee kannasta tarkasteltavan oluen: <code>@beer = Beer.find(params[:id])</code>


Näkymätemplatea /views/beers/show.html.erb muutetaan seuraavasti:

```erb
<h2> <%= @beer %> </h2>

<p>
  <strong>Style:</strong>
  <%= @beer.style %>
</p>

<% if @beer.ratings.empty? %>
  <p>beer has not yet been rated!</p>
<% else %>
  <p>has been rated <%= @beer.ratings.count %> times, average score <%= @beer.average_rating %></p>
<% end %>

<% if current_user %>

  <h4>give a rating:</h4>

  <%= form_for(@rating) do |f| %>
    <%= f.hidden_field :beer_id %>
    score: <%= f.number_field :score %>
    <%= f.submit %>
  <% end %>

  <%= link_to 'Edit', edit_beer_path(@beer) %>

<% end %>
```

Jotta lomake lähettäisi oluen id:n, tulee <code>beer_id</code>-kenttä lisätä lomakkeeseen. Emme kuitenkaan halua käyttäjän pystyvän manipuloimaan kenttää, joten kenttä on määritelty lomakkeelle <code>hidden_field</code>:iksi.

Koska lomake on luotu <code>form_for</code>-helperillä, tapahtuu sen lähettäminen automaattisesti HTTP POST -pyynnöllä <code>ratings_path</code>:iin eli reittauskontrollerin <code>create</code>-metodi käsittelee lomakkeen lähetyksen. Kontrolleri toimii ilman muutoksia!

Ratkaisussa on pieni ongelma. Jos reittauksessa yritetään antaa epävalidi pistemäärä:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-3.png)

renderöi kontrolleri (eli reittauskontrollerin metodi <code>create</code>) oluen näkymän sijaan uuden reittauksen luomislomakkeen:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-4.png)

Ongelman voisi kiertää katsomalla mistä osoitteesta create-metodiin on tultu ja renderöidä sitten oikea sivu riippuen tulo-osoitteesta. Emme kuitenkaan tee nyt tätä muutosta.

Korjaamme ensin erään vielä vakavamman ongelman. Edellistä kahta kuvaa tarkastelemalla huomaamme että jos reittauksen (joka yritetään antaa oluelle _Huvila Pale Ale_) validointi epäonnistuu, ei tehty oluen valinta ole enää tallessa (valittuna on _iso 3_).

Ongelman syynä on se, että pudotusvalikon vaihtoehdot generoivalle metodille <code>options_from_collection_for_select</code> ei ole kerrottu mikä vaihtoehdoista tulisi valita oletusarvoisesti, ja tälläisessä tilanteessa valituksi tulee kokoelman ensimmäinen olio. Oletusarvoinen valinta kerrotaan antamalla metodille neljäs parametri:

```erb
    options_from_collection_for_select(@beers, :id, :to_s, selected: @rating.beer_id) %>
```

Eli muutetaan näkymätemplate app/views/ratings/new.html.erb seuraavaan muotoon:

```erb
<h2>Create new rating</h2>

<%= form_for(@rating) do |f| %>
    <% if @rating.errors.any? %>
        <div id="error_explanation">
          <h2><%= pluralize(@rating.errors.count, "error") %> prohibited rating from being saved:</h2>

          <ul>
            <% @rating.errors.full_messages.each do |msg| %>
                <li><%= msg %></li>
            <% end %>
          </ul>
        </div>
    <% end %>

    <%= f.select :beer_id, options_from_collection_for_select(@beers, :id, :to_s, selected: @rating.beer_id) %>
    score: <%= f.number_field :score %>

    <%= f.submit %>
<% end %>
```

Sama ongelma itse asiassa vaivaa muutamia sovelluksemme lomakkeita, kokeile esim. mitä tapahtuu kun editoit oluen tietoja. Korjaa lomake jos haluat.

> ## Tehtävä 7
>
> Tee myös olutkerhoihin liitttyminen mahdolliseksi suoraan olutkerhon sivulta.
>
> Kannattaa noudattaa samaa toteutusperiaatetta kuin oluen sivulta tapahtuvassa reittaamisessa, eli lisää olutseuran sivulle lomake, jonka avulla voidaan luoda uusi <code>Membership</code>-olio, joka liittyy olutseuraan ja kirjautuneena olevaan käyttäjään. Lomakkeeseen ei tarvita muuta kuin 'submit'-painike:
>
>```erb
>  <%= form_for(@membership) do |f| %>
>     <%= f.hidden_field :beer_club_id %>
>     <%= f.submit value:"join the club" %>
>  <% end %>
>```

Hienosäädetään olutseuraan liittymistä

> ## Tehtävä 8
>
> Tee ratkaisustasi sellainen, jossa liittymisnappia ei näytetä jos kukaan ei ole kirjautunut järjestelmään tai jos kirjautunut käyttäjä on jo seuran jäsen.
>
> Muokkaa koodiasi siten (membership-kontrollerin sopivaa metodia), että olutseuraan liittymisen jälkeen selain ohjautuu olutseuran sivulle ja sivu näyttää allaolevan kuvan mukaisen ilmoituksen uuden käyttäjän liittymisestä.

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-5.png)

> ## Tehtävä 9
>
> Laajennetaan toiminnallisuutta vielä siten, että jäsenten on mahdollisuus erota olutseurasta.
>
> Lisää olutseuran sivulle nappi, joka mahdollistaa seurasta eroamisen. Napin tulee olla näkyvillä vain jos kirjautunut käyttäjä menee sellaisen seuran sivulle, jossa hän on jäsenenä. Eroamisnappia painamalla jäsenyys tuhoutuu ja käyttäjä ohjautuu omalle sivulleen jolla tulee näyttää ilmoitus eroamisesta, allaolevat kuvat selventävät haluttua toiminnallisuutta.
>
> Vihje: eroamistoiminnallisuuden voi toteuttaa liittymistoiminnalisuuden tapaan olutseuran sivulle sijoitettavalla lomakkeella. Lomakkeen käyttämäksi HTTP-metodiksi tulee määritellä delete:
>
>```erb
>    <%= form_for(@membership, method: "delete") do |f| %>
>       <%= f.hidden_field :beer_club_id %>
>       <%= f.submit value: "end the membership" %>
>    <% end %>
>```
>
> **HUOM:** saatat saada virheilmoituksen <code>No route matches [DELETE] "/memberships"</code>
>
> Syynä tälle on se, että routes-tiedoston määrittely määrittelee HTTP Delete -operaation vaan polulle, joka on muotoa _/memberships/:id_, eli esim. _memberships/42_
>
> Metodi <code>form_for</code> tuottaa polun muotoa _memberships_ jos sen parametrina oleva olio _ei ole_ talletettu tietokantaan. Jos parametrina oleva olio on talletettu tietokantaan, generoituva polku on muotoa _memberships/42_, missä 42 siis parametrina olevan olion id.
>
> Lomaketta käytettäessä on siis kontrollerissa asetettava muuttujan <code>@membership</code> arvoksi käyttäjän seuraan liittävä olio.

Jos käyttäjä on seuran jäsen, näytetän seuran sivulla eroamisen mahdollistava painike:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-5a.png)

Erottaessa seurasta tehdään uudelleenohjaus käyttäjän sivulle ja näytetään asianmukainen ilmoitus:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-5b.png)


## Migraatioista

Olemme käyttäneet Railsin migraatioita jo ensimmäisestä viikosta alkaen. On aika syventyä aihepiiriin hieman tarkemmin.

> ## Tehtävä 10
>
> Lue ajatuksella http://guides.rubyonrails.org/migrations.html

## Oluttyyli

> ## Tehtävät 11-13 (vastaa kolmea tehtävää)
>
> Laajenna sovellustasi siten, että oluttyyli ei ole enää merkkijono, vaan tyylit on talletettu tietokantaan. Jokaiseen oluttyyliin liittyy myös tekstuaalinen kuvaus. Tyylin kuvauksen tyypiksi kannattaa määritellä <code>text</code>, tyypin <code>string</code> avulla määritellyn sarakkeen oletuskoko on nimittäin vain 255 merkkiä.
>
> Muutoksen jälkeen oluen ja tyylin suhteen tulee olla seuraava

![kuva](http://yuml.me/30b291af)

> Huomaa, oluella nyt oleva attribuutti <code>style</code> tulee poistaa, jotta ei synnyt ristiriitaa assosiaation ansiosta generoitavan aksessorin ja vanhan kentän välille.
>
> Saattaa olla hieman haasteellista suorittaa muutos siten, että oluet linkitetään automaattisesti oikeisiin tyylitietokannan tauluihin.
> Tämäkin onnistuu, jos teet muutoksen useassa askeleessa, esim:
> * luo tietokantataulu tyyleille
> * tee tauluun rivi jokaista _beers_-taulusta löytyvää erinimistä tyyliä kohti (tämä onnistuu konsolista käsin)
> * uudelleennimeä _beers_-taulun sarake style esim. _old_style_:ksi (tämä siis migraation avulla)
> * liitä konsolista käsin oluet _style_-olioihin käyttäen hyväksi oluilla vielä olevaa old_style-saraketta
> * tuhoa oluiden taulusta migraation avulla _old_style_
>
> **Huomaa, että Heroku-instanssin ajantasaistaminen kannattaa tehdä samalla!**
>
> Vielä hienompaa on tehdä kaikki edelliset askeleet yksittäisen migraation sisällä.
>
> Vihje: voit harjoitella datamigraation tekemistä siten, että kopioit ennen migraation aloittamista tietokannan eli tiedoston _db/development.sqlite3_ ja jos migraatiossa menee jokin pieleen, voit palauttaa tilanteen ennalleen kopion avulla. Myös byebug saattaa osoittautua hyödylliseksi migraation kehittelemisessä.
>
> Voit myös suorittaa siirtymisen uusiin tietokannassa oleviin tyyleihin suoraviivaisemmin eli poistamalla oluilta _style_-sarakkeen ja asettamalla oluiden tyylit esim. konsolista.
>
> Muutoksen jälkeen uutta olutta luotaessa oluen tyyli valitaan panimoiden tapaan valmiilta listalta. Lisää myös tyylien sivulle vievä linkki navigaatiopalkkiin.
>
> Tyylien sivulle kannattaa lisätä lista kaikista tyylin oluista.
>
> **HUOM** Jos et tee myös datan migraatiota migraatiotiedostojen avulla, tämä tehtävä todennäköisesti hajottaa Travisin. Voit merkitä tehtävän siitä huolimatta. Travisia ei ole pakko pitää toimintakunnossa kurssin seuraavilla viikoilla. Toki on syytä potea hieman huonoa omaatuntoa, jos Travis-build rikkoutuu.

Tehtävän jälkeen oluttyylin sivu voi näyttää esim. seuraavalta

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-6.png)

**HUOM:** varmista, että uusien oluiden luominen toimii vielä laajennuksen jälkeen! Joudut muuttamaan muutamaakin kohtaa, näistä vaikein huomata lienee olutkontrollerin apumetodi <code>beer_params</code>.

Hyvä lista oluttyyleistä kuvauksineen löytyy osoitteesta http://beeradvocate.com/beer/style/

> ## Tehtävä 14
>
> Tyylien tallettaminen tietokantaan hajottaa suuren osan  testeistä. Ajantasaista testit. Huomaa, että myös FactoryGirlin tehtaisiin on tehtävä muutoksia.
>
> Vaikka hajonneita testejä on suuri määrä, älä mene paniikkiin. Selvitä ongelmat testi testiltä, yksittäinen ongelma kertautuu monteen paikkaan ja testien ajantasaistaminen ei ole loppujenlopuksi kovin vaikeaa.

## Tehtävien palautus

Commitoi kaikki tekemäsi muutokset ja pushaa koodi Githubiin. Deployaa myös uusin versio Herokuun.

Tehtävät kirjataan palautetuksi osoitteeseen http://wadrorstats2016.herokuapp.com/

