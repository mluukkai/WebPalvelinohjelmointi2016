Jatkamme sovelluksen rakentamista siitä, mihin jäimme viikon 5 lopussa. Allaoleva materiaali olettaa, että olet tehnyt kaikki edellisen viikon tehtävät. Jos et tehnyt kaikkia tehtäviä, voit ottaa kurssin repositorioista [edellisen viikon mallivastauksen](https://github.com/mluukkai/WebPalvelinohjelmointi2016/tree/master/mallivastaukset/viikko5). Jos sait suurimman osan edellisen viikon tehtävistä tehtyä, saattaa olla helpointa, että täydennät vastaustasi mallivastauksen avulla.

Jos otat edellisen viikon mallivastauksen tämän viikon pohjaksi, kopioi hakemisto muualle kurssirepositorion alta (olettaen että olet kloonannut sen) ja tee sovelluksen sisältämästä hakemistosta uusi repositorio.

## Testeistä

Osa tämän viikon tehtävistä saattaa hajottaa jotain edellisinä viikkoina tehtyjä testejä. Voit merkitä tehtävät testien hajoamisesta huolimatta, eli testien pitäminen kunnossa on vapaaehtoista.

## Bootstrap

Toistaiseksi emme ole kiinnittäneet ollenkaan huomiota sovelluksiemme ulkoasuun. Modernin ajattelun mukaan HTML-koodi määrittelee ainoastaan sivujen tietosisällön ja ulkoasu määritellään erillisissä CSS-tiedostoissa.

HTML:ssä merkataan elementtejä _luokilla_ (class), ja _id_:illä, jotta tyylitiedostojen määrittelemiä tyylejä saadaan ohjattua halutuille kohtiin sivua.

Määrittelimme jo muutama viikko sitten, että application layoutiin sijoittamamme navigointipalkki sijaitsee div-elementisssä jolle on asetettu luokka "navibar":

```erb
<div class="navibar">
  <%= link_to 'breweries', breweries_path %>
  <%= link_to 'beers', beers_path %>
  <%= link_to 'styles', styles_path %>
  <%= link_to 'ratings', ratings_path %>
  <%= link_to 'users', users_path %>
  <%= link_to 'clubs', beer_clubs_path %>
  <%= link_to 'places', places_path %>
  |
  <% if not current_user.nil? %>
    <%= link_to current_user.username, current_user %>
    <%= link_to 'rate a beer', new_rating_path %>
    <%= link_to 'join a club', new_membership_path %>
    <%= link_to 'signout', signout_path, method: :delete %>
  <% else %>
    <%= link_to 'signin', signin_path %>
    <%= link_to 'signup', signup_path %>
  <% end %>
</div>
```

Määrittelimme viikolla 2 navigointipalkille tyylin lisäämällä hakemistossa app/assets/stylesheats/ sijaitsevaan tiedostoon application.css seuraavat:

```css
.navibar {
    padding: 10px;
    background: #EFEFEF;
}
```

CSS:ää käyttämällä koko sivuston ulkoasu voitaisiin muotoilla sivuston suunnittelijan haluamalla tavalla, jos silmää ja kykyä muotoiluun löytyy.

Sivuston muotoilunkaan suhteen ei onneksi ole enää tarvetta keksiä pyörää uudelleen. Bootstrap (vanhalta nimeltään Twitter Bootstrap) http://getbootstrap.com/ on "kehys", joka sisältää suuren määrän web-sivujen ulkoasun muotoiluun tarkoitettuja CSS-tyylitiedostoja ja javascriptiä. Bootstrap onkin noussut nopeasti suureen suosioon web-sivujen ulkoasun muotoilussa.

Aloitetaan sitten sovelluksemme bootstrappaaminen gemin https://github.com/twbs/bootstrap-sass. Lisätään Gemfileen seuraavat:

```ruby
gem 'bootstrap-sass'
group :development do
  gem 'rails_layout'
end
```

Otetaan gemit käyttöön komennolla <code>bundle install</code>.

Generoidaan seuraavaksi sovellukselle Bootstrapin tarvitsemat tiedostot.
**Ota kuitenkin ensin talteen sovelluksen navigaatiopalkin generoiva koodi.** Suoritetaan sitten bootstrapin tarvitsemien tiedostojen generointi (mm. tiedoston application.html.erb ylikirjottavalla) komennolla

    rails generate layout:install bootstrap3 --force

Käynnistetään rails server uudelleen. Kun nyt avaamme sovelluksen selaimella, huomaamme jo pienen muutoksen esim. fonteissa. Myös navigointipalkki on hävinnyt.

**HUOM:** jos hakemistoon app/assets/stylesheets jäi vielä tiedosto application.css, saatat joutua poistamaan sen sillä yo. skripti on luonut korvaavan tiedoston _application.css.scss_

Edellä suorittamamme komento on luonut navigointipalkkia varten hakemistoon app/views/layout tiedostot *&#95;navigation.html.erb* ja *&#95;navigation&#95;links.html.erb*

Kuten arvata saattaa, navigointipalkkiin tulevat linkit sijoitetaan tiedostoon *&#95;navigation&#95;links.html.erb*. Jokainen linkki tulee sijoittaa li-tagin sisälle. Lisää tiedostoon seuraavat:

```erb
<li><%= link_to 'breweries', breweries_path %></li>
<li><%= link_to 'beers', beers_path %></li>
<li><%= link_to 'styles', styles_path %></li>
<li><%= link_to 'ratings', ratings_path %></li>
<li><%= link_to 'users', users_path %></li>
<li><%= link_to 'clubs', beer_clubs_path %></li>
<li><%= link_to 'places', places_path %></li>
<% if not current_user.nil? %>
    <li><%= link_to current_user.username, current_user %></li>
    <li><%= link_to 'rate a beer', new_rating_path %></li>
    <li><%= link_to 'join a club', new_membership_path %></li>
    <li><%= link_to 'signout', signout_path, method: :delete %></li>
<% else %>
    <li><%= link_to 'signin', signin_path %></li>
    <li><%= link_to 'signup', signup_path %></li>
<% end %>
```

Sen lisäksi että Bootstrapilla voi helposti muodostaa navigointipalkin, joka pysyy jatkuvasti sivun ylälaidassa, voidaan Bootstrapin grid-järjestelmän avulla jakaa sivu erillisiin osiin, ks. http://getbootstrap.com/css/#grid

Muutetaan sovelluksen layoutin eli tiedoston application.html.erb sivupohjan renderöivää osaa seuraavasti:

```erb
  <body>
    <header>
      <%= render 'layouts/navigation' %>
    </header>

    <main role="main" class=".container">
      <%= render 'layouts/messages' %>

      <div class="row">
        <div class="col-md-8">
          <%= yield %>
        </div>
        <div class="col-md-4">
          <img src="http://www.cs.helsinki.fi/u/mluukkai/wadror/pint.jpg" width="200">
        </div>
      </div>

    </main>
  </body>
```

Eli sijoitamme bootstrapin containeriin yhden rivin, jonka jaamme kahteen sarakkeeseen: 8:n levyiseen johon kunkin sivun tiedot upotetaan ja 4:n levyiseen osaan jossa näytämme kuvan.

Sivun pohja on nyt kunnossa ja voimme hyödyntää bootstrapin tyylejä ja komponentteja sivuillamme.

Navigaatio määriteltiin jo *navbar*-komponentin ks. http://getbootstrap.com/components/#navbar avulla.

Muotoillaan seuraavaksi hieman sivulla käyttämiämme taulukoita. Bootstrapin sivulta http://getbootstrap.com/css/#tables näemme, että taulukon normaali bootstrap-muotoilu saadaan käyttöön lisäämällä taulukon HTML-koodille luokka <code>table</code>, seuraavasti:

```erb
<table class="table">
  ...
</table>
```

Lisätään luokkamäärittely esim. oluiden sivulle ja kokeillaan. Näyttää jo paljon professionaalimmalta. Päätetään vielä lisätä luokka <code>table-hover</code>, jonka ansioista se rivi jonka kohdalla hiiri on muuttuu korostetuksi, eli taulukon luokkamäärittelyksi tulee

```erb
<table class="table table-hover">
  ...
</table>
```

> ## Tehtävä 1
>
> Muuta ainakin muutama sovelluksen taulukoista käyttämään bootstrapin tyylejä.
>
>

Bootstrap tarjoaa valmiit tyylit myös painikkeille http://getbootstrap.com/css/#buttons

Päätetään käyttää luokkaparin <code>btn btn-primary</code> määrittelemää sinistä painiketta. Seuraavassa esimerkki, missä luokka on lisätty oluen reittauksen tekevälle painikkeelle:

```erb
  <h4>give a rating:</h4>

  <%= form_for(@rating) do |f| %>
    <%= f.hidden_field :beer_id %>
    score: <%= f.number_field :score %>
    <%= f.submit class:"btn btn-primary" %>
  <% end %>
```

Luokka voidaan lisätä myös niihin linkkeihin, jotka halutaan napin painikkeen näköisiksi:

```erb
<%= link_to 'New Beer', new_beer_path, class:'btn btn-primary' %>
```

> ## Tehtävä 2
>
> Lisää sovelluksen ainakin muutamille painikkeille ja painikkeen tapaan toimiville linkeille valitut tyylit. Poisto-operaatioissa tyyliksi kannattaa laittaa <code>btn btn-danger</code>.


> ## Tehtävä 3
>
> Muuta navigointipalkkia siten, että käyttäjän kirjautuessa kirjautunutta käyttäjää koskevat toiminnot tulevat menupalkin dropdowniksi alla olevan kuvan tapaan.
>
> Ohjeita löydät dokumentista http://getbootstrap.com/components/#nav-dropdowns

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w6-3.png)

> ## Tehtävä 4
>
> Tee jostain sivustosi osasta tyylikkäämpi käyttämällä jotain Bootstrapin komponenttia. Saat merkitä rastin jos käytät aikaa sivustosi ulkoasun parantamiseen vähintään 15 minuuttia. Saat rastin myös jos muutat loputkin sovelluksen taulukoista ja napeista käyttämään bootstrapin tyylejä.

## Scopet

Osa panimoista on jo lopettanut toimintansa ja haluaisimme eriyttää lopettaneet panimot aktiivisten panimoiden listalta. Lisätään painimotietokantaan aktiivisuuden merkkaava boolean-arvoinen sarake. Luodaan migraatio:

    rails g migration AddActivityToBrewery active:boolean

Huom: koska migraation nimi alkaa sanalla Add ja loppuu olion nimeen Brewery, ja sisältää tiedon lisättävästä sarakkeesta, generoituu juuri oikea migraatiokoodi automaattisesti.

Suoritetaan migraatio ja käydään konsolista käsin merkkaamassa kaikki tietokannassa olevat panimot aktiiviseksi:

```ruby
irb(main):020:0> Brewery.all.each{ |b| b.active=true; b.save }
```

Käydään luomassa uusi panimo, jotta saamme tietokantaamme myös yhden epäaktiivisen panimon.

Muutetaan sitten panimon sivua siten, että se kertoo panimon mahdollisen epäaktiivisuuden panimon nimen vieressä:

```erb
<h2><%= @brewery.name %>
  <% if not @brewery.active  %>
      <span class="label label-info">retired</span>
  <% end %>
</h2>

<p>
  <em>Established year:</em>
  <%= @brewery.year %>
</p>

<p>Number of beers <%= @brewery.beers.count%> </p>

<ul>
 <% @brewery.beers.each do |beer| %>
   <li><%= link_to beer.name, beer %></li>
 <% end %>
</ul>

<% if @brewery.ratings.empty? %>
    <p>beers of the brewery have not yet been rated! </p>
<% else %>
    <p>Has <%= pluralize(@brewery.ratings.count,'rating') %>, average <%= @brewery.average_rating %> </p>
<% end %>

<% if current_user %>
  <%= link_to 'Edit', edit_brewery_path(@brewery), class:"btn btn-primary"  %>
  <%= link_to 'Destroy', @brewery, method: :delete, data: { confirm: 'Are you sure?' }, class:"btn btn-danger"  %>
<% end %>
```

Panimon luomis- ja editointilomakkeeseen on syytä lisätä mahdollisuus panimon aktiivisuuden asettamiseen. Lisätään views/breweries/_form.html.erb:iin checkbox aktiivisuuden säätelyä varten:

```erb
  <div class="field">
    <%= f.label :active %>
    <%= f.check_box :active %>
  </div>
```

Kokeillaan. Huomaamme kuitenkin että aktiivisuuden muuttaminen ei toimi.

Syynä tälle on se, että attribuuttia <code>active</code> ei ole lueteltu  massasijoitettavaksi sallittujen attribuuttien joukossa.

Tutkitaan hieman panimokontrolleria. Sekä uuden panimon luominen, että panimon tietojen muuttaminen hakevat panimoon liittyvät tiedot metodin <code>brewery_params</code> avulla:

```ruby

  def create
    @brewery = Brewery.new(brewery_params)

    # ...
  end

  def update
    # ...
    if @brewery.update(brewery_params)
    # ...
  end

  def brewery_params
    params.require(:brewery).permit(:name, :year)
  end
```

Kuten [viikolla 2 totesimme](
https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#reittauksen-talletus) on jokainen massasijoitettavaksi tarkoitettu attribuutti eksplisiittisesti sallittava <code>permit</code> metodin avulla. Muutetaan metodia <code>brewery_params</code> seuraavasti:
```ruby
  def brewery_params
    params.require(:brewery).permit(:name, :year, :active)
  end
```

Päätetään, että haluamme näyttää panimoiden listalla erikseen aktiiviset ja epäaktiiviset panimot. Suoraviivainen ratkaisu on seuraava. Talletetaan kontrollerissa aktiiviset ja passiiviset omiin muuttujiinsa:

```ruby
  def index
    @active_breweries = Brewery.where(active:true)
    @retired_breweries = Brewery.where(active:[nil, false])
  end
```

Kentän <code>active</code>-arvo voi olla joko eksplisiittisesti asetettu <code>false</code> tai <code>nil</code> jotka molemmat tarkoittavat eläköitynyttä panimoa, olemme joutuneet lisäämään jälkimmäiseen <code>where</code>-lauseeseen molemmat vaihtoehdot.

Copypastetaan näkymään taulukko kahteen kertaan, erikseen aktiivisille ja eläköityneille:

```erb
<h1>Breweries</h1>

<h2>Active</h2>

<p> Number of active breweries: <%= @active_breweries.count %> </p>

<table class="table table-hover">
  <thead>
    <tr>
    <th>Name</th>
    <th>Year</th>
    </tr>
  </thead>

  <tbody>
    <% @active_breweries.each do |brewery| %>
      <tr>
        <td><%= link_to brewery.name, brewery %></td>
        <td><%= brewery.year %></td>
        <td></td>
      </tr>
    <% end %>
  </tbody>
</table>

<h2>Retired</h2>

<p> Number of retired breweries: <%= @retired_breweries.count %> </p>

<table class="table table-hover">
  <thead>
  <tr>
    <th>Name</th>
    <th>Year</th>
  </tr>
  </thead>

  <tbody>
  <% @retired_breweries.each do |brewery| %>
      <tr>
        <td><%= link_to brewery.name, brewery %></td>
        <td><%= brewery.year %></td>
        <td></td>
      </tr>
  <% end %>
  </tbody>
</table>

<br>

<%= link_to 'New Brewery', new_brewery_path, class:"btn btn-primary"  %>
```

Ratkaisu on toimiva, mutta siinä on parillakin tapaa parantamisen varaa. Parannellaan ensin kontrolleria.

Kontrolleri siis haluaa listan sekä aktiivisista että jo lopettaneista panimoista. Kontrolleri myös kertoo kuinka nuo listat haetaan tietokannasta.

Voisimme tehdä kontrollerista siistimmän, jos luokka <code>Brewery</code> tarjoaisi mukavamman rajapinnan panimoiden listan hakuun. ActiveRecord tarjoaa tähän mukavan ratkaisun, scopet, ks. http://guides.rubyonrails.org/active_record_querying.html#scopes

Määritellään nyt panimoille kaksi scopea, aktiiviset ja eläköityneet:

```ruby
class Brewery < ActiveRecord::Base
  include RatingAverage

  validates :name, presence: true
  validates :year, numericality: { less_than_or_equal_to: ->(_) { Time.now.year} }

  scope :active, -> { where active:true }
  scope :retired, -> { where active:[nil,false] }

  has_many :beers, :dependent => :destroy
  has_many :ratings, :through => :beers
end
```

Scope määrittelee luokalle metodin, joka palauttaa kaikki scopen määrittelevän kyselyn palauttamat oliot.

Nyt <code>Brewery</code>-luokalta saadaan pyydettyä kaikkien panimoiden lisäksi mukavan rajapinnan avulla aktiiviset ja lopettaneet panimot:

    Brewery.all      # kaikki panimot
    Brewery.active   # aktiiviset
    Brewery.retired  # lopettaneet

Kontrollerista tulee nyt elegantti:

```ruby
  def index
    @active_breweries = Brewery.active
    @retired_breweries = Brewery.retired
  end
```

Ratkaisu on luettavuuden lisäksi parempi myös olioiden vastuujaon kannalta. Ei ole järkevää laittaa kontrollerin vastuulle sen kertomista _miten_ aktiiviset ja eläköityneet panimot tulee hakea kannasta, sen sijaan tämä on hyvin luontevaa antaa modelin vastuulle, sillä modelin rooli on nimenomaan toimia abstraktiokerroksena muun sovelluksen ja tietokannan välillä.

Kannattaa huomioida, että ActiveRecord mahdollistaa operaatioiden ketjuttamisen. Voitaisiin kirjoittaa esim:

```ruby
  Brewery.where(active:true).where("year>2000")
```

ja tuloksena olisi SQL-kysely

```sql
  SELECT "breweries".* FROM "breweries" WHERE "breweries"."active" = ? AND (year>2000)
```

ActiveRecord osaa siis optimoida ketjutetut metodikutsut yhdeksi SQL-operaatioksi. Myös scope toimii osana ketjutusta, eli vuoden 2000 jälkeen persutetut, edelleen aktiiviset panimot saataisiin selville myös seuraavalla 'onlinerilla':

```ruby
  Brewery.active.where("year>2000")
```

## Partiaalit

Siistitään seuraavaksi panimolistan näyttötemplatea. Templatessa on nyt käytännössä sama taulukko kopioituna kahteen kertaan peräkkäin. Eristämme taulukon omaksi __partiaaliksi__, eli näyttötemplateen upotettavaksi tarkoitetuksi näyttötemplaten palaksi, ks. http://guides.rubyonrails.org/layouts_and_rendering.html#using-partials.

Annetaan partialille nimi views/breweries/_list.html.erb (Huom: partialien nimet ovat aina alaviiva-alkuisia!). Sisältö on seuraava:

```erb
<table class="table table-hover">
  <thead>
  <tr>
    <th>Name</th>
    <th>Year</th>
  </tr>
  </thead>

  <tbody>
  <% breweries.each do |brewery| %>
      <tr>
        <td><%= link_to brewery.name, brewery %></td>
        <td><%= brewery.year %></td>
        <td></td>
      </tr>
  <% end %>
  </tbody>
</table>
```

Partiaali viittaa nyt taulukkoon sijoitettavien panimoiden listaan nimellä <code>breweries</code>.

Kaikki panimot renderöivä template ainoastaan *renderöi partiaalin* ja lähettää sille renderöitävän panimolistan parametriksi:

```erb
<h1>Breweries</h1>

<h2>Active</h2>

<p> Number of active breweries: <%= @active_breweries.count %> </p>

<%= render 'list', breweries: @active_breweries %>

<h2>Retired</h2>

<p> Number of retired breweries: <%= @retired_breweries.count %> </p>

<%= render 'list', breweries: @retired_breweries %>

<br>

<%= link_to 'New Brewery', new_brewery_path, class:"btn btn-primary"  %>

```

Panimoiden sivun template on nyt lähes silmiä hivelevä!

> ## Tehtävä 5-6 (kahden tehtävän arvoinen)
>
> Ratings-sivumme on tällä hetkellä hieman tylsä. Muuta sivua siten, että sillä näytetään reittausten sijaan:
>* kolme reittausten keskiarvon perusteella parasta olutta ja  panimoa
>* kolme eniten reittauksia tehnyttä käyttäjää
>* viisi viimeksi tehtyä reittausta.
>
> **Vihjeitä:**
> Tee luokalle <code>Rating</code> scope <code>:recent</code>, joka palauttaa viisi viimeisintä reittausta. Scopen vaatimaan tietokantakyselyyn löydät apuja linkistä http://guides.rubyonrails.org/active_record_querying.html, ks. order ja limit. Kokeile ensin kyselyn tekoa konsolista!
>
> Parhaiden oluet ja panimot sekä innokkaimmat reittaajat kertovien scopejen teko ei onnistu yhtä helposti, sillä scopen palauttamat oliot pitäisi selvittää tietokantatasolla eli tarvittaisiin monimutkaista SQL:ää.
>
> Scopejen sijaan voit tehdä luokille <code>Brewery</code>, <code>Beer</code> ja <code>User</code> luokkametodit (eli Javan terminologiassa staattiset metodit), joiden avulla kontrolleri saa haluamansa panimot, oluet ja käyttäjät. Esim. panimolla metodi olisi suunilleen seuraavanlainen:
>
>```ruby
>class Brewery
>  # ...
>
>  def self.top(n)
>    sorted_by_rating_in_desc_order = Brewery.all.sort_by{ |b| -(b.average_rating||0) }
>    # palauta listalta parhaat n kappaletta
>    # miten? ks. http://www.ruby-doc.org/core-2.1.0/Array.html
>  end
>end
>```
>
> Metodia käytetään nyt kontrollerista seuraavasti:
>
>```ruby
>  @top_breweries = Brewery.top 3
>```
>
> Huom: oluiden, tyylien  ja panimoiden <code>top</code>-metodit ovat oikeastaan copypastea ja moduuleja käyttämällä olisi mahdollista saada koodin määrittely siirrettyä yhteen paikkaan. Kun olet tehnyt viikon kaikki tehtävät voit yrittää siistiä koodisi!
>
> __Älä copypastaa näyttöjen koodia vaan käytä tarvittaessa partiaaleja.__

> ## Tehtävä 7
>
> Lisää reittausten sivulle myös parhaat kolme oluttyyliä

Reittausten sivu voi näyttää tehtävävien jälkeen esim. seuraavalta:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w6-4.png)

Sivun muotoiluun voi olla apua seuraavasta: http://getbootstrap.com/css/#grid-nesting


## Näyttöjen koodin siistiminen helpereillä

Viikolla 3 lisäsimme luokkaan <code>ApplicationController</code> metodin <code>current_user</code> jonka määrittelimme myös ns. helper-metodiksi

```ruby
class ApplicationController < ActionController::Base
  # ...
  helper_method :current_user

 end
```

näin sekä kontrollerit että näkymät voivat tarvittaessa käyttää metodia kirjaantuneena olevan käyttäjän identiteetin tarkastamiseen. Koska metodi on määritelty luokkaan <code>ApplicationController</code> on se automaattisesti kaikkien kontrollerien käytössä. Helper-metodiksi määrittely tuo metodin myös näkymien käyttöön.

Sovelluksissa on usein tarve kirjoittaa apumetodeja (eli Railsin terminologian mukaan helper-metodeja) pelkästään näyttötemplateja varten. Tällöin niitä ei kannata sijoittaa <code>ApplicationController</code>-luokkaan vaan hakemiston _app/helpers/_ alla oleviin moduuleihin. Jos apumetodia on tarkoitus käyttää useammasta näytöstä, on oikea sijoituspaikka <code>application_helper</code>, jos taas apumetodit ovat tarpeen ainoastaan yhden kontrollerin alaisuudessa olevilla sivuilla, kannattaa ne määritellä ko. kontrolleria vastaavaan helper-moduliin.

Huomaamme, että näyttöjemme koodissa on joitain toistuvia osia. Esim. oluen, tyylin ja panimon show.html.erb-templateissa on kaikissa hyvin samantapainen koodi, jolla sivulle luodaan tarvittaessa linkit editointia ja poistamista varten:

```erb
<%= if current_user %>
  <%= link_to 'Edit', edit_beer_path(@beer), class:"btn btn-primary" %>

  <%= link_to 'Delete', @beer, method: :delete, data: { confirm: 'Are you sure?' }, class:"btn btn-danger"  %>
<% end %>
```

Eriytetään nämä omaksi helperiksi, moduliin application_helper.rb

```ruby
module ApplicationHelper
  def edit_and_destroy_buttons(item)
    unless current_user.nil?
      edit = link_to('Edit', url_for([:edit, item]), class:"btn btn-primary")
      del = link_to('Destroy', item, method: :delete,
                    data: {confirm: 'Are you sure?' }, class:"btn btn-danger")
      raw("#{edit} #{del}")
    end
  end

end
```

Metodi muodostaa link_to:n avulla kaksi HTML-linkkielementtiä ja palauttaa molemmat "raakana" (ks. http://apidock.com/rails/ActionView/Helpers/RawOutputHelper/raw), eli käytännössä HTML-koodina, joka voidaan upottaa sivulle.

Painikkeet lisätään esim. oluttyylin sivulle seuraavasti:

```erb
<h2>
  <%= @style.name %>
</h2>

<quote>
  <%= @style.description %>
</quote>

...

<%= edit_and_destroy_buttons(@style) %>
```

Näytön muodostava template siistiytyykin huomattavasti.

Painikkeet muodostava koodi olisi pystytty myös eristämään omaan partialiin, ja onkin hiukan makuasia kumpi on tässä tilanteessa parempi ratkaisu, helper-metodi vai partiali.

> ## Tehtävä 8
>
> Usealla sovelluksen sivulla näytetään reittausten keskiarvoja. Keskiarvot ovat Decimal-tyyppiä, joten ne tulostuvat välillä hieman liiankin monen desimaalin tarkkuudella. Määrittele reittausten keskiarvon renderöintiä varten apumetodi <code>round(param)</code>, joka tulostaa aina parametrinsa __yhden__ desimaalin tarkkuudella, ja ota apumetodi käyttöön (ainakin joissakin) näyttötemplateissa.
>
> Voit käyttää helpperissäsi esim. Railsista löytyvää <code>number_with_precision</code>-metodia, ks. http://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_with_precision

## Reitti panimon statuksen muuttamiselle

Lisäsimme hetki sitten panimoille tiedon niiden aktiivisuudesta ja mahdollisuuden muuttaa panimon aktiivisuusstatusta panimon tietojen editointilomakkeesta. Kuvitellaan hieman epärealistisesti, että panimot voisivat vähän väliä lopettaa ja aloittaa jälleen toimintansa. Tällöin aktiivisuusstatuksen muuttaminen panimon tietojen editointilomakkeelta olisi hieman vaivalloista. Tälläisessä tilanteessa olisikin kätevämpää, jos esim. kaikkien panimoiden listalla olisi panimon vieressä nappi, jota painamalla panimon aktiivisuusstatuksen muuttaminen onnistuisi. Voisimme toteuttaa tälläisen napin upottamalla panimoiden listalle jokaisen panimon kohdalle sopivan lomakkeen. Teemme kuitenkin nyt toisenlaisen ratkaisun. Lisäämme panimoille Railsin oletusarvoisen kuuden reitin lisäksi uuden reitin <code>toggle_activity</code>, johon tehdyn HTTP POST -kutsun avulla panimon aktiivisuusstatusta voi muuttaa.

Tehdään tiedostoon routes.rb seuraava muutos panimon osalta:

```ruby
  resources :breweries do
    post 'toggle_activity', on: :member
  end
```

Kun nyt teemme komennon <code>rake routes</code> huomaamme panimolle ilmestyneen uuden reitin:

```ruby
toggle_activity_brewery POST   /breweries/:id/toggle_activity(.:format) breweries#toggle_activity
              breweries GET    /breweries(.:format)                     breweries#index
                        POST   /breweries(.:format)                     breweries#create
            new_brewery GET    /breweries/new(.:format)                 breweries#new
           edit_brewery GET    /breweries/:id/edit(.:format)            breweries#edit
                brewery GET    /breweries/:id(.:format)                 breweries#show
                        PUT    /breweries/:id(.:format)                 breweries#update
                        DELETE /breweries/:id(.:format)                 breweries#destroy
```

Päätämme lisätä aktiivisuusstatuksen muutostoiminnon yksittäisen panimon sivulle. Eli lisätään panimon sivulle app/views/breweries/show.html.erb seuraava:

```erb
<%= link_to "change activity", toggle_activity_brewery_path(@brewery.id), method: :post, class: "btn btn-primary" %>
```

Kun nyt klikkaamme painiketta, tekee selain HTTP POST -pyynnön osoitteeseen /breweries/:id/toggle_activity, missä :id on sen panimon id, jolla linkkiä klikattiin. Railsin reititysmekanismi yrittää kutsua breweries-kontrollerin metodia <code>toggle_activity</code> jota ei ole, joten seurauksena on virheilmoitus. Metodi voidaan toteuttaa esim. seuraavasti:

```ruby
  def toggle_activity
    brewery = Brewery.find(params[:id])
    brewery.update_attribute :active, (not brewery.active)

    new_status = brewery.active? ? "active" : "retired"

    redirect_to :back, notice:"brewery activity status changed to #{new_status}"
  end
```

Tominnallisuuden toteuttaminen oli varsin helppoa, mutta onko reitin <code>toggle_activity</code> lisääminen järkevää? RESTful-ideologian mukaan puhdasoppisempaa olisi ollut hoitaa asia lomakkeen avulla, eli polkuun breweries/:id kohdistuneella PUT-pyynnöllä. Jokatapauksessa tulee välttää tilanteita, joissa resurssin tilaa muutettaisiin GET-pyynnöllä, ja tästä syystä määrittelimmekin polun toggle_activity ainoastaan POST-pyynnöille.

Lisää custom routeista sivulla
http://guides.rubyonrails.org/routing.html#adding-more-restful-actions

## Admin-käyttäjä ja pääsynhallintaa

> ## Tehtävä 9
>
> Tällä hetkellä kuka tahansa kirjautunut käyttäjä voi poistaa panimoja, oluita ja olutseuroja. Laajennetaan järjestelmää siten, että osa käyttäjistä on administraattoreja, ja poisto-operaatioit ovat vain sallittuja vain heille
>
> * luo User-modelille uusi boolean-muotoinen kenttä <code>admin</code>, jonka avulla merkataan ne käyttäjät joilla on ylläpitäjän oikeudet järjestelmään
> * riittää, että käyttäjän voi tehdä ylläpitäjäksi ainoastaan konsolista
> * tee panimoiden, oluiden, olutseurojen ja tyylien poisto-operaatioista ainoastaan ylläpitäjälle mahdollinen toimenpide
>
> **Huom:** salasanan validoinnin takia käyttäjän tekeminen adminiksi konsolista ei onnistu, jos salasanakenttiin ei ole asetettu arvoja:
>
>```ruby
>irb(main):001:0> u = User.first
>irb(main):002:0> u.admin = true
> irb(main):003:0> u.save
>   (0.1ms)  rollback transaction
> => false
>```
>
> Yksittäisten attribuuttien arvon muuttaminen on kuitenkin mahdollista validaation kiertävällä metodilla <code>update_attr</code>:
>
> ```ruby
> irb(main):005:0> u.update_attribute(:admin, true)
> ```
>
> Validointien suorittamisen voi ohittaa myös tallentamalla olion komennolla <code>u.save(validate: false)</code>
>
> **HUOM:** toteutuksessa kannattanee hyödyntää [esifiltteriä](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko4.md#kirjautuneiden-toiminnot)

> ## Tehtävä 10-11 (kahden tehtävän arvoinen)
>
> Toteuta toiminnallisuus, jonka avulla administraattorit voivat jäädyttää jonkin käyttäjätunnuksen. Jäädyttäminen voi tapahtua esim. napilla, jonka vain administraattorit näkevät käyttäjän sivulla. Jäädytetyn tunnuksen omaava käyttäjä ei saa päästä kirjautumaan järjestelmään. Yrittäessään kirjautumista, sovellus huomauttaa käyttäjälle että hänen tunnus on jäädytetty ja kehoittaa ottamaan yhteyttä ylläpitäjiin. Administraattorien tulee pystyä palauttamaan jäädytetty käyttäjätunnus ennalleen.
>
> **HUOM:** älä määrittele Userille attribuuttia nimeltä <code>frozen</code>, kyseessä on kielletty attribuutin nimi!
>
> Voit toiteuttaa toiminnallisuuden esim. allaolevien vihjaamaan kuvien tapaan

Administraattori voi jäädyttää käyttäjätunnuksen käyttäjän sivulta

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w6-1c.png)

Administraattori näkee käyttäjien näkymästä jäädytetyt käyttäjätunnukset

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w6-1b.png)

Jos käyttjätunnus on jäädytetty kirjautuminen ei onnistu

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w6-1a.png)

Administraattori voi uudelleenaktivoida jäädytetyn käyttäjätunnuksen käyttäjän sivulta

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w6-1d.png)

## Monimutkaisempi pääsynhallinta

Jos sovelluksessa on tarvetta monipuolisempaan pääsynhallintaan (engl. authorization), kannattanee asia hoitaa esim. _cancan_-gemin avulla ks. https://github.com/CanCanCommunity/cancancan ja
http://railscasts.com/episodes/192-authorization-with-cancan

Aihetta esittelevä Rails cast on jo aika ikääntynyt, eli tarkemmat ohjeet kannattaa katsoa projektin Github-sivulta. Rails castit tarjoavat todella hyviä esittelyjä monista aihepiireistä, eli vaikka castit eivät enää olisi täysin ajantasalla kaikkien detaljien suhteen, kannattaa ne usein silti katsoa läpi.

## Rails-sovellusten tietoturvasta

Emme ole vielä toistaiseksi puhuneet mitään Rails-sovellusten tietoturvasta. Nyt on aika puuttua asiaan. Rails-guideissa on tarjolla erinomainen katsaus tyypillisimmistä web-sovellusten tietoturvauhista ja siitä miten Rails-sovelluksissa voi uhkiin varautua.

> ## Tehtävät 12-14 (kolmen tehtävän arvoinen)
>
> Lue http://guides.rubyonrails.org/security.html
>
> Teksti on pitkä mutta asia on tärkeä. Jos haluat optimoida ajankäyttöä, jätä luvut 4, 5 ja 7.4-7.8 lukematta.
>
> Voit merkata tehtävät tehdyksi kun seuraavat asiat selvillä
> * SQL-injektio
> * CSRF
> * XSS
> * järkevä sessioiden käyttö
>
> Tietoturvaan liittyen kannattaa katsoa myös seuraavat
> * http://guides.rubyonrails.org/action_controller_overview.html#force-https-protocol
> * http://guides.rubyonrails.org/action_controller_overview.html#log-filtering

Yo. dokumentista ei käy täysin selväksi se, että Rails _sanitoi_ (eli escapettaa kaikki script- ja html-tagit yms) oletusarvoisesti sivuilla renderöitävän syötteen, eli esim. jos yrittäisimme syöttää javascript-pätkän <code> &lt;script&gt;alert(&#39;Evil XSS attack&#39;);&lt;/script&gt;</code> oluttyylin kuvaukseen, koodia ei suoriteta, vaan koodi renderöityy sivulle 'tekstinä':

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-7.png)

Jos katsomme sivun lähdekoodia, huomaamme, että Rails on korvannut HTML-tägit aloittavat ja sulkevat < -ja > -merkit niitä vastaavilla tulostuvilla merkeillä, jolloin syöte muuttuu selaimen kannalta normaaliksi tekstiksi:

```ruby
 &lt;script&gt;alert(&#39;Evil XSS attack&#39;);&lt;/script&gt;
```

Oletusarvoisen sanitoinnin saa 'kytkettyä pois' pyytämällä eksplisiittisesti metodin <code>raw</code> avulla, että renderöitävä sisältö sijoitetaan sivulle sellaisenaan. Jos muuttaisimme tyylin kuvauksen renderöintiä seuraavasti

```ruby
<p>
  <%= raw(@style.description) %>
</p>
```

suoritetaan javascript-koodi sivun renderöinnion yhteydessä:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w5-8.png)

Lisätietoa http://www.railsdispatch.com/posts/security ja http://railscasts.com/episodes/204-xss-protection-in-rails-3

## Metaohjelmointia: mielipanimoiden ja tyylin refaktorointi

Viikon 4 tehtävissä 3 ja 4 (ks. https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko4.md#teht%C3%A4v%C3%A4-3) toteutettiin metodit henkilön suosikkipanimon ja oluttyylin selvittämiseen. Seuraavassa on eräs suoraviivainen ratkaisu metodien <code>favorite_style</code> ja <code>favorite_brewery</code> toteuttamiseen:

```ruby
class User
  # ...
  def favorite_brewery
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.brewery }.uniq
    rated.sort_by { |brewery| -rating_of_brewery(brewery) }.first
  end

  def rating_of_brewery(brewery)
    ratings_of = ratings.select{ |r| r.beer.brewery==brewery }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end

  def favorite_style
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.style }.uniq
    rated.sort_by { |style| -rating_of_style(style) }.first
  end

  def rating_of_style(style)
    ratings_of = ratings.select{ |r| r.beer.style==style }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end

end
```

Tutkitaan mielipanimon selvittävää metodia:

```ruby
  def favorite_brewery
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.brewery }.uniq
    rated.sort_by { |brewery| -rating_of_brewery(brewery) }.first
  end
```

Erikostapauksen (ei yhtään reittausta) tarkamisen jälkeen metodi aloittaa selvittämällä minkä panimoiden oluita käyttäjä on reitannut:

```ruby
  rated = ratings.map{ |r| r.beer.brewery }.uniq
```

Komento siis palauttaa listan käyttäjän tekemiin reittauksiin liittyvistä panimoista siten. Komennon <code>uniq</code> ansiosta sama panimo ei esiinny listalla kuin kerran.

Toinen komento järjestää reitattujen panimoiden listan käyttäen järjestämiskriteerinä panimon saamien reittausten keskiarvoa ja palauttaa listan ensimmäisen, eli parhaan keskiarvoreittauksen saaneen panimon.

Keskiarvo lasketaan apumetodilla:

```ruby
  def rating_of_brewery(brewery)
    ratings_of = ratings.select{ |r| r.beer.brewery==brewery }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end
```

Apumetodi valitsee aluksi käyttäjän tekemistä reittauksista ne, jotka koskevat parametriksi annettua panimoa. Tämän jälkeen lasketaan valittujen reittausten pistemäärien keskiarvo.

Huomaamme, että <code>favorite_style</code> toimii _täsmälleen_ saman periaatteen mukaan ja metodi itse sekä sen käyttämät apumetodit ovatkin oikeastaan copypastea mielipanimon selvittämiseen käytettävästä koodista.


Koska ohjelmistossamme on kattavat testit, on copypaste helppo refaktoroida pois. Tutkitaan ensin apumetodeja jotka laskevat yhden panimon ja yhden tyylin reittausten keskiarvon:

```ruby
  def rating_of_style(style)
    ratings_of = ratings.select{ |r| r.beer.style==style }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end

  def rating_of_brewery(brewery)
    ratings_of = ratings.select{ |r| r.beer.brewery==brewery }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end
```

Uudelleennimetään metodien parametri:

```ruby
  def rating_of_style(item)
    ratings_of = ratings.select{ |r| r.beer.style==item }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end

  def rating_of_brewery(item)
    ratings_of = ratings.select{ |r| r.beer.brewery==item }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end
```

Huomaamme, että erona metodeissa on ainoastaan <code>select</code>-metodin koodilohkossa reittaukseen liittyvälle olut-oliolle kutsuttava metodi.

Kutsuttava metodi voidaan antaa myös parametrina. Tällöin eksplisiittisen kutsun sijaan metodia kutsutaan olion <code>send</code>-metodin avulla:

```ruby
  def rating_of(category, item)
    ratings_of = ratings.select{ |r| r.beer.send(category)==item }
    ratings_of.map(&:score).inject(&:+) / ratings_of.count.to_f
  end
```

Metodia voidaan nyt käyttää seuraavasti:

```ruby
2.2.1 :037 > u = User.first
2.2.1 :038 > u.rating_of :brewery , Brewery.find_by(name:"BrewDog")
 => 30.2
2.2.1 :031 > u.rating_of :style , Style.find_by(name:"American IPA")
 => 36.666666666666664
```

Eli voimme luopua alkuperäisistä apumetodeista ja käyttää uutta paramterisoitua metodia:

```ruby
  def favorite_style
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.style }.uniq
    rated.sort_by { |style| -rating_of(:style, style) }.first
  end

  def favorite_brewery
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.brewery }.uniq
    rated.sort_by { |brewery| -rating_of(:brewery, brewery) }.first
  end
```

Nimetään uudelleen metodien komennossa <code>sort_by</code> käyttämä apumuuttuja:

```ruby
  def favorite_style
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.style }.uniq
    rated.sort_by { |item| -rating_of(:style, item) }.first
  end

  def favorite_brewery
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.brewery }.uniq
    rated.sort_by { |item| -rating_of(:brewery, item) }.first
  end
```

Muutetaan <code>map</code> käytettävä metodikutsu muotoon <code>send</code>

```ruby
  def favorite_style
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.send(:style) }.uniq
    rated.sort_by { |item| -rating_of(:style, item) }.first
  end

  def favorite_brewery
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.send(:brewery) }.uniq
    rated.sort_by { |item| -rating_of(:brewery, item) }.first
  end
```

Määritellään parametrina oleva metodin nimi muuttujan <code>category</code> avulla:

```ruby
  def favorite_style
    return nil if ratings.empty?
    category = :style

    rated = ratings.map{ |r| r.beer.send(category) }.uniq
    rated.sort_by { |item| -rating_of(category, item) }.first
  end

  def favorite_brewery
    return nil if ratings.empty?
    category = :brewery

    rated = ratings.map{ |r| r.beer.send(category) }.uniq
    rated.sort_by { |item| -rating_of(category, item) }.first
  end
```

Nyt molempien metodien koodi on oikeastaan täysin sama. Yhteinen osa voidaankin eriyttää omaksi metodiksi:

```ruby
  def favorite_style
    favorite :style
  end

  def favorite_brewery
    favorite :brewery
  end

  def favorite(category)
    return nil if ratings.empty?

    rated = ratings.map{ |r| r.beer.send(category) }.uniq
    rated.sort_by { |item| -rating_of(category, item) }.first
  end
```


Uuden ratkaisumme etu on copypasten poiston lisäksi se, että jos oluelle määritellään jokun uusi "attribuutti", esim. väri, saamme samalla hinnalla mielivärin selvittävän metodin:

```ruby
  def favorite_color
    favorite :color
  end
```

## method_missing

Metodit <code>favorite_style</code> ja <code>favorite_brewery</code> olisi oikeastaan mahdollista saada toimimaan ilman niiden eksplisiittistä määrittelemistä.

Kommentoidaan metodit hetkeksi pois koodistamme.

Jos oliolle kutsutaan metodia, jota ei ole olemassa (määriteltynä luokassa itsessään, sen yliluokissa eikä missään luokan tai yliluokkien sisällyttämässä moduulissa), esim.

```ruby
2.2.1 :069 > u.paras_bisse
NoMethodError: undefined method `paras_bisse' for #<User:0x000001059cb0c0>
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/activemodel-4.1.5/lib/active_model/attribute_methods.rb:435:in `method_missing'
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/activerecord-4.1.5/lib/active_record/attribute_methods.rb:208:in `method_missing'
  from (irb):69
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/railties-4.1.5/lib/rails/commands/console.rb:90:in `start'
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/railties-4.1.5/lib/rails/commands/console.rb:9:in `start'
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/railties-4.1.5/lib/rails/commands/commands_tasks.rb:69:in `console'
2.2.1 :070 >
```

on tästä seurauksena se, että Ruby-tulkki kutsuu olion <code>method_missing</code>-metodia parametrinaan tuntemattoman metodin nimi. Rubyssä kaikki luokat perivät <code>Object</code>-luokan, joka määrittelee <code>method_missing</code>-metodin. Luokkien on sitten tarvittaessa mahdollista ylikirjoittaa tämä metodi ja saada näinollen aikaan "metodeja" joita ei ole olemassa, mutta jotka kutsujan kannalta toimivat aivan kuten normaalit metodit.

Rails käyttää sisäisesti metodia <code>method_missing</code> moniin tarkoituksiin. Emme voikaan suoraviivaisesti ylikirjoittaa sitä, meidän on muistettava delegoida <code>method_missing</code>-kutsut yliluokalle jollemme halua käsitellä niitä itse.

Määritellään luokalle <code>User</code> kokeeksi seuraavanlainen <code>method_missing</code>:

```ruby
  def method_missing(method_name, *args, &block)
    puts "nonexisting method #{method_name} was called with parameters: #{args}"
    return super
  end
```

kokeillaan:

```ruby
2.2.1 :072 > u.paras_bisse
nonexisting method paras_bisse was called with parameters: []
NoMethodError: undefined method `paras_bisse' for #<User:0x000001016af8e0>
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/activemodel-4.1.5/lib/active_model/attribute_methods.rb:435:in `method_missing'
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/activerecord-4.1.5/lib/active_record/attribute_methods.rb:208:in `method_missing'
  from /Users/mluukkai/kurssirepot/ratebeer/app/models/user.rb:30:in `method_missing'
2.2.1 :073 >
```

Eli kuten ylimmältä riviltä huomataan, suoritettiin määrittelemämme <code>method_missing</code>-metodi. Voimmekin ylikirjoittaa method_missingin seuraavasti:

```ruby
  def method_missing(method_name, *args, &block)
    if method_name =~ /^favorite_/
      category = method_name[9..-1].to_sym
      self.favorite category
    else
      return super
    end
  end
```

Nyt kaikki <code>favorite_</code>-alkuiset metodikutsut joita ei tunneta tulkitaan siten, että alaviivan jälkeinen osa eristetään ja kutsutaan oliolle metodia <code>favorite</code>, siten että alaviivan jälkiosa on kategorian määrittelevänä parametrina.

Nyt metodit <code>favorite_brewery</code> ja <code>favorite_style</code> "ovat olemassa" ja toimivat:

```ruby
2.2.1 :076 > u = User.first
2.2.1 :077 > u.favorite_brewery.name
 => "Malmgard"
2.2.1 :078 > u.favorite_style.name
  => "Baltic porter"
```

Ikävänä sivuvaikutuksena metodien määrittelystä method_missing:in avulla  on se, että mikä tahansa favorite_-alkuinen metodi "toimisi", mutta aiheuttaisi kenties epäoptimaalisen virheen.

```ruby
2.2.1 :079 > u.favorite_movie
NoMethodError: undefined method `movie' for #<Beer:0x00000105a18690>
  from /Users/mluukkai/.rvm/gems/ruby-2.2.1/gems/activemodel-4.1.5/lib/active_model/attribute_methods.rb:435:in `method_missing'
```

Ruby tarjoaa erilaisia mahdollisuuksia mm. sen määrittelemiseen, mitkä <code>favorite_</code>-alkuiset metodit hyväksyttäisiin. Voisimme esim. toteuttaa seuraavan rubymäisen tavan asian määrittelemiselle:

```ruby
class User < ActiveRecord::Base
  include RatingAverage

  favorite_available_by :style, :brewery

  # ...
end
```

Emme kuitenkaan lähde nyt tälle tielle. Hyöty tulisi näkyviin vasta jos favorite_-alkuisia metodeja voitaisiin hyödyntää muissakin luokissa.

Poistetaan kuitenkin nyt tässä tekemämme method_missing:iin perustuva toteutus ja palautetaan luvun alussa poiskommentoidut versiot.

Jos tässä luvussa esitellyn tyyliset temput kiinnostavat, voit jatkaa esim. seuraavista:

* http://rubymonk.com/learning/books/5-metaprogramming-ruby-ascent
* http://rubymonk.com/learning/books/2-metaprogramming-ruby
* https://github.com/sathish316/metaprogramming_koans
* myös kirja [Eloquent Ruby](http://www.amazon.com/Eloquent-Ruby-Addison-Wesley-Professional-Series/dp/0321584104) käsittelee aihepiiriä varsin hyvin


## Tehtävien palautus

Commitoi kaikki tekemäsi muutokset ja pushaa koodi Githubiin. Deployaa myös uusin versio Herokuun.

Tehtävät kirjataan palautetuksi osoitteeseen http://wadrorstats2016.herokuapp.com/

