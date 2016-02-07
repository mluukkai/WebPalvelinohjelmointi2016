Jatkamme sovelluksen rakentamista siitä, mihin jäimme viikon 3 lopussa. Allaoleva materiaali olettaa, että olet tehnyt kaikki edellisen viikon tehtävät. Jos et tehnyt kaikkia tehtäviä, voit ottaa kurssin repositorioista [edellisen viikon mallivastauksen](https://github.com/mluukkai/WebPalvelinohjelmointi2016/tree/master/malliv/viikko3). Jos sait suurimman osan edellisen viikon tehtävistä tehtyä, saattaa olla helpointa, että täydennät vastaustasi mallivastauksen avulla.

Jos otat edellisen viikon mallivastauksen tämän viikon pohjaksi, kopioi hakemisto muualle kurssirepositorion alta (olettaen että olet kloonannut sen) ja tee sovelluksen sisältämästä hakemistosta uusi repositorio.

**Huom:** muutamilla Macin käyttäjillä oli ongelmia Herokun tarvitseman pg-gemin kanssa. Paikallisesti gemiä ei tarvita ja se määriteltiinkin asennettavaksi ainoastaan tuotantoympäristöön. Jos ongelmia ilmenee, voit asentaa gemit antamalla <code>bundle install</code>-komentoon seuraavan lisämääreen:

    bundle install --without production

Tämä asetus muistetaan jatkossa, joten pelkkä `bundle install` riittää kun haluat asentaa uusia riippuvuuksia.

## Muutama huomio

### Ongelmia lomakkeiden kanssa

Viikolla 2 muutimme oluiden luomislomaketta siten, että uuden oluen tyyli ja panimo valitaan pudotusvalikoista. Lomake siis muutettiin käyttämään tekstikentän sijaan _select_:iä:

```ruby
  <div class="field">
    <%= f.label :style %><br>
    <%= f.select :style, options_for_select(@styles) %>
  </div>
  <div class="field">
    <%= f.label :brewery %><br>
    <%= f.select :brewery_id, options_from_collection_for_select(@breweries, :id, :name) %>
  </div>
```

eli pudotusvalikkojen valintavaihtoehdot välitettään lomakkeelle muuttujissa <code>@styles</code> ja <code>@breweries</code>, joille kontrollerin metodi <code>new</code> asettaa arvot:

```ruby
  def new
    @beer = Beer.new
    @breweries = Brewery.all
    @styles = ["Weizen", "Lager", "Pale ale", "IPA", "Porter"]
  end
```

Näiden muutosten jälkeen oluen tietojen editointi ei yllättäen enää toimi. Seurauksena on virheilmoitus <code>undefined method `map' for nil:NilClass</code>, johon olet kenties jo kurssin aikana törmännyt:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w4-0.png)

Syynä tälle on se, että uuden oluen luominen ja oluen tietojen editointi käyttävät molemmat samaa lomakkeen generoivaa näkymäätemplatea (app/views/beers/_form.html.erb) ja muutosten jälkeen näkymän toiminta edellyttää, että muuttuja <code>@breweries</code> sisältää panimoiden listan ja muuttuja <code>@styles</code> sisältää oluiden tyylit. Oluen tietojen muutossivulle mennään kontrollerimetodin <code>edit</code> suorituksen jälkeen, ja joudummekin muuttamaan kontrolleria seuraavasti korjataksemme virheen:

```ruby
  def edit
    @breweries = Brewery.all
    @styles = ["Weizen", "Lager", "Pale ale", "IPA", "Porter"]
  end
```

Täsmälleen samaan ongelmaan törmätään jos yritetään luoda olut, joka ei ole validi. Tällöin nimittäin kontrollerin metodi <code>create</code> yrittää renderöidä uudelleen lomakkeen generoivan näkymätemplaten. Metodissa on siis ennen renderöintiä asetettava arvo templaten tarvitsemille muuttujille <code>@styles</code> ja <code>@breweries</code>:

```ruby
  def create
    @beer = Beer.new(beer_params)

    respond_to do |format|
      if @beer.save
        format.html { redirect_to beers_path, notice: 'Beer was successfully created.' }
        format.json { render action: 'show', status: :created, location: @beer }
      else
        @breweries = Brewery.all
        @styles = ["Weizen", "Lager", "Pale ale", "IPA", "Porter"]

        format.html { render action: 'new' }
        format.json { render json: @beer.errors, status: :unprocessable_entity }
      end
    end
  end
```

Onkin hyvin tyypillistä, että kontrollerimetodit <code>new</code>, <code>create</code> ja <code>edit</code> sisältävät paljon samaa, näkymätemplaten tarvitsemien muuttujien alustukseen käytettyä koodia. Onkin järkevää ekstraktoida yhteinen koodi omaan metodiin:

```ruby
  def set_breweries_and_styles_for_template
    @breweries = Brewery.all
    @styles = ["Weizen", "Lager", "Pale ale", "IPA", "Porter"]
  end
```

Metodia voidaan kutsua kontrollerin metodeista <code>new</code>, <code>create</code> ja <code>edit</code>:

```ruby
  def new
    @beer = Beer.new
    set_breweries_and_styles_for_template
  end
```

 tai ehkä vielä tyylikkäämpää on hoitaa asia <code>before_action</code> määreellä:

```ruby
class BeersController < ApplicationController
  # ...
  before_action :set_breweries_and_styles_for_template, only: [:new, :edit, :create]

  # ...
```

tällöin muuttujien <code>@styles</code> ja <code>@breweries</code> arvot asettava metodi siis suoritetaan automaattisesti aina ennen metodien
<code>new</code>, <code>create</code> ja <code>edit</code> suoritusta. Metodissa <code>create</code> muuttujien arvot asetetaan ehkä turhaan sillä niitä tarvitaan ainoastaan validoinnin epäonnistuessa. Kenties olisikin parempi käyttää eksplisiittistä kutsua createssa.

### Ongelmia Herokun kanssa

Moni kurssin osallistujista on törmännyt siihen, tää paikallisesti loistavasti toimiva sovellus on aiheuttanut Herokussa pahaenteisen virheilmoituksen _We're sorry, but something went wrong_.

Heti ensimmäisenä kannattaa tarkistaa, että paikalliselta koneelta kaikki koodi on lisätty versionhallintaan, eli <code>git status</code>

Epätriviaalit ongelmat selviävät aina Herokun lokin avulla. Lokia päästään tutkimaan komentoriviltä komennolla <code>heroku logs</code>

Seuraavassa tyypillisen ongelmatilanteen loki:

```ruby
mbp-18:ratebeer-public mluukkai$ heroku logs
2016-02-03T18:53:05.867973+00:00 app[web.1]:                   ON a.attrelid = d.adrelid AND a.attnum = d.adnum
2016-02-03T18:53:05.867973+00:00 app[web.1]:
2016-02-03T18:53:05.867973+00:00 app[web.1]:                                           ^
2016-02-03T18:53:05.867973+00:00 app[web.1]:                WHERE a.attrelid = '"users"'::regclass
2016-02-03T18:53:05.874380+00:00 app[web.1]: Completed 500 Internal Server Error in 10ms
2016-02-03T18:53:05.878587+00:00 app[web.1]: :               SELECT a.attname, format_type(a.atttypid, a.atttypmod),
2016-02-03T18:53:05.878587+00:00 app[web.1]:                                           ^
2016-02-03T18:53:05.878587+00:00 app[web.1]:
2016-02-03T18:53:05.868310+00:00 app[web.1]:
2016-02-03T18:53:05.867973+00:00 app[web.1]:                      pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod
2016-02-03T18:53:05.867973+00:00 app[web.1]:                  AND a.attnum > 0 AND NOT a.attisdropped
2016-02-03T18:53:05.868310+00:00 app[web.1]:                ORDER BY a.attnum
2016-02-03T18:53:05.878587+00:00 app[web.1]:                WHERE a.attrelid = '"users"'::regclass
2016-02-03T18:53:05.867973+00:00 app[web.1]:                 FROM pg_attribute a LEFT JOIN pg_attrdef d
2016-02-03T18:53:05.882824+00:00 app[web.1]: LINE 5:                WHERE a.attrelid = '"users"'::regclass
2016-02-03T18:53:05.882824+00:00 app[web.1]:                                           ^
2016-02-03T18:53:05.878587+00:00 app[web.1]:                      pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod
2016-02-03T18:53:05.878587+00:00 app[web.1]:                   ON a.attrelid = d.adrelid AND a.attnum = d.adnum
2016-02-03T18:53:05.874380+00:00 app[web.1]: Completed 500 Internal Server Error in 10ms
2016-02-03T18:53:05.878587+00:00 app[web.1]: ActiveRecord::StatementInvalid (PG::UndefinedTable: ERROR:  relation "users" does not exist
```

lokia tarkasti lukemalla selviää että syynä on seuraava

```ruby
ActiveRecord::StatementInvalid (PG::UndefinedTable: ERROR:  relation "users" does not exist
```
eli migraatiot ovat jääneet suorittamatta. Korjaus on helppo:

    heroku run rake db:migrate

Seuraavassa loki eräästä toisesta hyvin tyypillisestä virhetilanteesta:

```ruby
2016-02-03T19:04:43.830852+00:00 app[web.1]: Started POST "/ratings" for 84.253.203.234 at 2016-02-03 19:04:43 +0000
2016-02-03T19:04:43.833992+00:00 app[web.1]:   Parameters: {"utf8"=>"✓", "authenticity_token"=>"n1VTj7WrICHZUT594fbxJBue2uqcSk6wrYQR7lY5nzk=", "rating"=>{"beer_id"=>"2", "score"=>"10"}, "commit"=>"Create Rating"}
2016-02-03T19:04:43.833913+00:00 app[web.1]: Processing by RatingsController#create as HTML
2016-02-03T19:04:43.833992+00:00 app[web.1]: Processing by RatingsController#create as HTML
2016-02-03T19:04:43.833992+00:00 app[web.1]:   Parameters: {"utf8"=>"✓", "authenticity_token"=>"n1VTj7WrICHZUT594fbxJBue2uqcSk6wrYQR7lY5nzk=", "rating"=>{"beer_id"=>"2", "score"=>"10"}, "commit"=>"Create Rating"}
2016-02-03T19:04:43.853276+00:00 app[web.1]:
2016-02-03T19:04:43.851427+00:00 app[web.1]: Completed 500 Internal Server Error in 19ms
2016-02-03T19:04:43.852028+00:00 app[web.1]: Completed 500 Internal Server Error in 19ms
2016-02-03T19:04:43.853276+00:00 app[web.1]:   app/controllers/ratings_controller.rb:15:in `create'
2016-02-03T19:04:43.853276+00:00 app[web.1]:
2016-02-03T19:04:43.853276+00:00 app[web.1]: NoMethodError (undefined method `ratings' for nil:NilClass):
2016-02-03T19:04:43.853276+00:00 app[web.1]:   app/controllers/ratings_controller.rb:15:in `create'
2016-02-03T19:04:43.853276+00:00 app[web.1]:
2016-02-03T19:04:43.853276+00:00 app[web.1]:
2016-02-03T19:04:43.853276+00:00 app[web.1]: NoMethodError (undefined method `ratings' for nil:NilClass):
2016-02-03T19:04:43.853276+00:00 app[web.1]:
```

Virhe on aiheutunut tiedoston *app/controllers/ratings_controller.rb* rivillä 15 ja syynä on <code>NoMethodError (undefined method `ratings' for nil:NilClass)</code>.

Katsotaan ko. tiedostoa ja ongelman aiheuttanutta riviä:

```ruby
  def create
    @rating = Rating.new params.require(:rating).permit(:score, :beer_id)

    if @rating.save
      current_user.ratings << @rating  ## virheen aiheuttanut rivi
      redirect_to user_path current_user
    else
      @beers = Beer.all
      render :new
    end
  end
```

eli ongelman aiheutti se, että yritettiin tehdä reittaus tilanteessa, jossa kukaan ei ollut kirjaantuneena ja <code>current_user</code> oli <code>nil</code>. Ongelma voidaan korjata esim. seuraavasti:

```ruby
  def create
    @rating = Rating.new params.require(:rating).permit(:score, :beer_id)

    if current_user.nil?
      redirect_to signin_path, notice:'you should be signed in'
    elsif @rating.save
      current_user.ratings << @rating  ## virheen aiheuttanut rivi
      redirect_to user_path current_user
    else
      @beers = Beer.all
      render :new
    end
  end
```

eli jos käyttäjä ei ole kirjautunut, ohjataan selain kirjautumissivulle. Kannattaa myös poistaa _ratings_-näkymään ehkä jäänyt linkki, joka mahdollistaa reittauksen yrittämisen kirjautumattomana.

Tarkastellaan lopuksi erään suorastaan klassikon asemaan nousseen virheen lokia:

```ruby
2016-02-03T19:32:31.609344+00:00 app[web.1]:     6:   <% @ratings.each do |rating| %>
2016-02-03T19:32:31.609530+00:00 app[web.1]:
2016-02-03T19:32:31.609530+00:00 app[web.1]:
2016-02-03T19:32:31.609530+00:00 app[web.1]:   app/views/ratings/index.html.erb:6:in `_app_views_ratings_index_html_erb___254869282653960432_70194062879340'
2016-02-03T19:32:31.609530+00:00 app[web.1]:
2016-02-03T19:32:31.609530+00:00 app[web.1]: ActionView::Template::Error (undefined method `username' for nil:NilClass):
2016-02-03T19:32:31.609344+00:00 app[web.1]:   app/views/ratings/index.html.erb:7:in `block in _app_views_ratings_index_html_erb___254869282653960432_70194062879340'
2016-02-03T19:32:31.609530+00:00 app[web.1]:     7:       <li> <%= rating %> <%= link_to rating.user.username, rating.user %> </li>
2016-02-03T19:32:31.609530+00:00 app[web.1]:     4:
2016-02-03T19:32:31.609530+00:00 app[web.1]:     6:   <% @ratings.each do |rating| %>
2016-02-03T19:32:31.609530+00:00 app[web.1]:     5: <ul>
2016-02-03T19:32:31.609715+00:00 app[web.1]:    10:
```

Tarkka silmä huomaa lokin seasta että ongelma on _ActionView::Template::Error (undefined method `username' for nil:NilClass)_ ja virhe syntyi tiedoston _app/views/ratings/index.html.erb_ riviä 7 suoritettaessa. Virheen aiheuttanut rivi on

```ruby
<li> <%= rating %> <%= link_to rating.user.username, rating.user %> </li>
```

vaikuttaa siis siltä, että tietokannassa on <code>rating</code>-olio, johon liittyvä <code>user</code> on <code>nil</code>. Kyseessä on siis jo [viikolta 2 tuttu](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#ongelmia-herokussa) ongelma.

Ongelman perimmäinen syy on joko se, että jonkin ratingin <code>user_id</code>-kentän arvo on <code>nil</code>, tai että jonkin rating-olion <code>user_id</code>:n arvona on virheellinen id. Tilanteesta selvitään esim. tuohoamalla 'huonot' rating-oliot komennolla <code>heroku run console</code> käynnistyvän Herokun konsolin avulla:


```ruby
irb(main):001:0> bad_ratings = Rating.all.select{ |r| r.user.nil? or r.beer.nil? }
=> [#<Rating id: 1, score: 10, beer_id: 2, created_at: "2016-02-03 19:04:43", updated_at: "2016-02-03 19:04:43", user_id: nil>]
irb(main):002:0> bad_ratings.each{ |bad| bad.destroy }
=> [#<Rating id: 1, score: 10, beer_id: 2, created_at: "2016-02-03 19:04:43", updated_at: "2016-02-03 19:04:43", user_id: nil>]
irb(main):003:0> Rating.all.select{ |r| r.user.nil? or r.beer.nil? }
=> []
irb(main):004:0>
```

Ylläoleva hakee varalta kannasta myös ratingit, joihin ei liity mitään olemassaolevaa olutta.

Eli jos joudut Herokun kanssa ongelmiin, selvitä analyyttisesti mistä on kyse, loki ja konsoli auttavat aina hädässä!

### Migraation peruminen

Silloin tällöin (esim. jos luodaan vahingossa huono scaffold, ks. seuraava kohta) syntyy tilanteita, joissa edelliseksi suoritetettu migraatio on syytä perua. Tämä onnistuu komennolla

    rake db:rollback

### Huono scaffold

Jos haluat poistaa scaffold-generaattorin luomat tiedostot, onnistuu tämä komennolla

    rails destroy scaffold resursin_nimi

missä _resurssin_nimi_ on scaffoldilla luomasi resurssin nimi. **HUOM:** jos suoritit jo huonoon scaffoldiin liittyvän migraation, tee ehdottomasti ennen scaffoldin tuhoamista <code>rake db:rollback</code>


## Testaaminen

Toistaiseksi olemme tehneet koodia, jonka toimintaa olemme testanneet ainoastaan selaimesta. Tämä on suuri virhe. Jokaisen eliniältään laajemmaksi tarkoitetun ohjelman on syytä sisältää riittävän kattavat automaattiset testit, muuten ajan mittaan käy niin että ohjelman laajentaminen tulee liian riskialttiiksi.

Käytämme testaukseen Rspec:iä ks. http://rspec.info/,  https://github.com/rspec/rspec-rails ja http://betterspecs.org/

Otetaan käyttöön rspec-rails gem lisäämällä Gemfileen seuraava:

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 3.0'
end
```

Uusi gem otetaan käyttöön tutulla tavalla, eli antamalla komentoriviltä komento <code>bundle install</code>

rspec saadaan initialisoitua sovelluksen käyttöön antamalla komentoriviltä komento

    rails generate rspec:install

Initialisointi luo sovellukselle hakemiston /spec jonka alihakemistoihin testit eli "spekit" sijoitetaan.

Railsin oletusarvoinen, mutta nykyään vähemmän käytetty testausframework sijoittaa testit hakemistoon /test. Ko. hakemisto on tarpeeton rspecin käyttöönoton jälkeen ja se voidaan poistaa.

Testejä (oikeastaan rspecin yhteydessä ei pitäisi puhua testeistä vaan speceistä tai spesifikaatioista, käytämme kuitenkin jatkossa sanaa testi) voidaan kirjoittaa usealla tasolla: yksikkötestejä modeleille tai kontrollereille, näkymätestejä, integraatiotestejä kontrollereille.  Näiden lisäksi sovellusta voidaan testata käyttäen simuloitua selainta capybara-gemin https://github.com/jnicklas/capybara avulla.

Kirjoitamme jatkossa lähinnä yksikkötestejä modeleille sekä capybaran avulla simuloituja selaintason testejä.

## Yksikkötestit

Tehdään kokeeksi muutama yksikkötesti luokalle <code>User</code>. Voimme luoda testipohjan käsin tai komentoriviltä rspec-generaattorilla

    rails generate rspec:model user

Hakemistoon /spec/models tulee tiedosto user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
```

Kokeillaan ajaa testit komentoriviltä komennolla <code>rspec spec</code> (huom: saattaa olla, että joudut tässä vaiheessa käynnistämään terminaalin uudelleen!).

Se mitä komentoa suoritettaessa nyt tapahtuu, riippuen käyttämästäsi Railsin versiosta.

## Testien suorittaminen vanhemmalla Railsin versiolla

Jos käytössäsi on hieman vanhempi versio Railsista, esim. Rails 4.0 käy todennäköisesti seuraavalla tavalla:

```ruby
$ rspec spec
/Users/mluukkai/.rvm/gems/ruby-2.0.0-p451/gems/activerecord-4.0.2/lib/active_record/migration.rb:379:in `check_pending!': Migrations are pending; run 'bin/rake db:migrate RAILS_ENV=test' to resolve this issue. (ActiveRecord::PendingMigrationError)
```

eli seurauksena on melko ikävä, noin 30 riviä pitkä virheilmoitus. Virheilmoituksen seasta, heti sen alusta löytyy kuitenkin syy ongelmalla

     Migrations are pending; run 'bin/rake db:migrate RAILS_ENV=test' to resolve this issue.

eli migraatiot ovat jostain syystä suorittamatta. Syynä tälle on [viikolla 1](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko1.md#riippuvuuksien-hallinta-ja-suoritusymp%C3%A4rist%C3%B6t) esiin nostamamme seikka, eli Railsissa on käytössä oma ympäristö sovelluskehitykseen, tuotantoon ja testaamiseen ja jokaisessa ympäristössä on käytössä oma tietokanta. Vaikka sovelluskehitysympäristön tietokannan migraatiot ovat ajan tasalla, ei testausympäristön migraatioita ole suoritettu ja sen takia testienkään suorittaminen ei onnistu.

*Huom:* uudemmilla Railsin versioilla testitietokannan migraatiot suoritetaan automaattisesti rspecin alustuksen yhteydessä ja et törmää edellä olevaan virheilmoitukseen.

Testiympäristön migraatiot on mahdollista suorittaa komennolla <code>rake db:migrate RAILS_ENV=test</code>, kannattaa kuitenkin suorittaa komentoriviltä testiympäristön ajantasaistaminen yleisemmin käytetyn komento

    rake db:test:prepare

ja tämän jälkeen suorittaa testit uudelleen komennolla <code>rspec spec</code>


## testien suorittaminen uudemmilla Railsin versiolla

Uudemmilla Railsin versioilla (4.1 ja sitä uudemmat) testitietokannan migraatiot siis suoritetaan automaattisesti rspecin alustuksen yhteydessä ja edellisessä luvussa kuvattua virhetilannetta ei esiinny.

Ensimmäinen testien suoritus etenee seuraavasti:

```ruby
$ rspec spec
*

Pending:
  User add some examples to (or delete) /Users/mluukkai/kurssirepot/rors/lagi/spec/models/user_spec.rb
    # Not yet implemented
    # ./spec/models/user_spec.rb:4

Finished in 0.00047 seconds (files took 1.48 seconds to load)
1 example, 0 failures, 1 pending
```

*Huom* jos testi toimii muuten mutta saat testien ajamisen yhteydessä suuren määrän epämääräisiä virheilmoituksia , lisää tiedostoon _spec/spec_hepler.rb_ seuraava rivi

```ruby
  config.warnings = false
```

Rivin tulee sijaita tiedostossa olevan <code>do</code> <code>end</code> -lohkon sisällä.

Komento  <code>rspec spec</code> määrittelee, että suoritetaan kaikki testit, jotka löytyvät hakemiston spec alihakemistoista. Jos testejä on paljon, on myös mahdollista ajaa suppeampi joukko testejä:

    rspec spec/models                # suoritetaan hakemiston model sisältävät testit
    rspec spec/models/user_spec.rb   # suoritetaan user_spec.rb:n määrittelemät testi

rspec-rails luo myös rake-komennot eli taskit testien suorittamiseen. Voit listata kaikki testeihin liittyvät taskit komennolla ```rake -T spec```.

```ruby
$ rake -T spec
rake spec         # Run all specs in spec directory (excluding plugin specs)
rake spec:models  # Run the code examples in spec/models
```

eli komento <code>rake spec</code> saa aikaan saman kuin <code>rspec spec</code>:

```ruby
$ rake spec
*

Pending:
  User add some examples to (or delete) /Users/mluukkai/kurssirepot/wadror/ratebeer/spec/models/user_spec.rb
    # No reason given
    # ./spec/models/user_spec.rb:4

Finished in 0.00046 seconds
1 example, 0 failures, 1 pending

Randomized with seed 7711
```

Komennon <code>rspec spec</code> ja <code>rake spec</code> erona on se, että rake:lla suoritettaessa testiympäristön tietokanta päivitetään automaattisesti, eli käytettäessä komentoa <code>rake spec</code> ei ole tarvetta komennon <code>rake db:test:prepare</code> suorittamiselle vaikka tietokannan skeemassa olisikin muutoksia. Käytämme materiaalissa jatkossa <code>rspec</code>-komentoa.

Huomaa, että komento <code>rake spec</code> toimii (suoraan) ainoastaan jos gemi <code>rspec-rails</code> on määritelty Gemfilessä testiscopen lisäksi myös tuotantoscopeen.

Testien ajon voi myös automatisoida aina kun testi tai sitä koskeva koodi muuttuu. [guard](https://github.com/guard/guard) on tähän käytetty kirjasto ja siihen löytyy monia laajennoksia.

Aloitetaan testien tekeminen. Kirjoitetaan aluksi testi joka testaa, että konstruktori asettaa käyttäjätunnuksen oikein:

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  it "has the username set correctly" do
    user = User.new username:"Pekka"

    user.username.should == "Pekka"
  end
end
```

Testi kirjoitetaan <code>it</code>-nimiselle metodille annettavan koodilohkon sisälle. Metodin ensimmäisenä parametrina on merkkijono, joka toimii testin nimenä. Muuten testi kirjoitetaan "xUnit-tyyliin", eli ensin luodaan testattava data, sitten suoritetaan testattava toimenpide ja lopuksi varmistetaan että vastaus on odotettu.

Suoritetaan testi ja havaitaan sen menevän läpi:

```ruby
$ rspec spec

Finished in 0.00553 seconds (files took 2.11 seconds to load)
1 example, 0 failures
$
```

Testin suorituksta seuraa myös varoitus vanhahtavan syntaksin käytöstä. Unohdetaan varoitus hetkeksi ja tarkastellaan testin sisältöä.

Toisin kuin xUnit-perheen testauskehyksissä, Rspecin yhteydessä ei käytetä assert-komentoja testin odotetun tuloksen määrittelemiseen. Käytössä on hieman erikoisemman näköinen syntaksi, kuten testin viimeisellä rivillä oleva:

    user.username.should == "Pekka"

Rspec lisää jokaiselle luokalle metodin <code>should</code>, jonka avulla voidaan määritellä testin odotettu käyttäytyminen siten, että määrittely olisi luettavuudeltaan mahdollisimman luonnollisen kielen ilmaisun kaltainen.

Kuten aina Rubyssä, on myös Rspecissä useita vaihtoehtoisia tapoja tehdä sama asia. Metodin should sijaan edellinen voitaisiin kirjoittaa myös modernimman rspec-tyylin mukaisesti:

    expect(user.username).to eq("Pekka")

Rspecin versiosta 3 alkaen vanhempi should-syntaksi on deprekoitu, eli sitä ei tulisi enää käyttää.
Shouldin muuttaminen expectiksi poisti myös <code>Deprecation Warning</code>in

Käytämme jatkossa sekaisin molempia tyylejä, mutta pääasiassa expectiä.

Äskeisessä testissä käytettiin komentoa <code>new</code>, joten olioa ei talletettu tietokantaan. Kokeillaan nyt olion tallettamista. Olemme määritelleet, että User-olioilla tulee olla salasana, jonka pituus on vähintään 4 ja että salasana sisältää sekä numeron että ison kirjaimen. Eli jos salasanaa ei aseteta, ei oliota tulisi tallettaa tietokantaan. Testataan että näin tapahtuu:

```ruby
  it "is not saved without a password" do
    user = User.create username:"Pekka"

    expect(user.valid?).to be(false)
    expect(User.count).to eq(0)
  end
```

Testi menee läpi.

Testin ensimmäinen tarkistus

```ruby
   expect(user.valid?).to be(false)
```

on kyllä ymmärrettävä, mutta kiitos rspec-magian, voimme ilmaista sen myös seuraavasti

```ruby
    expect(user).not_to be_valid
```

Tämän muodon toiminta perustuu sille, että oliolla <code>user</code> on totuusarvoinen metodi <code>valid?</code>.

Huomaamme, että käytämme testeissä kahta samuuden tarkastustapaa <code>be(false)</code> ja <code>eq(0)</code>, mikä näillä on erona? Matcherin eli 'tarkastimen' <code>be</code> avulla voidaan varmistaa, että kyse on kahdesta samasta oliosta. Totuusarvojen vertaulussa <code>be</code> onkin toimiva tarkistin. Esim. merkkijonojen vertailuun se ei toimi, kokeile muuttaa ensimmäisen testin vertailu muotoon:

```ruby
  expect(user.username).to be("Pekka")
```
nyt testi ei mene läpi:

```ruby
       expected #<String:70243704887740> => "Pekka"
            got #<String:70243704369920> => "Pekka"
```

Kun riittää että vertailtavat oliot ovat sisällöltään samat, tuleekin käyttää tarkistinta <code>eq</code>, käytännössä useimmissa tilanteissa näin on kaikkien muiden paitsi totuusarvojen kanssa. Tosin totuusarvojenkin <code>eq</code> toimisi eli voisimme kirjoittaa myös

```ruby
   expect(user.valid?).to eq(false)
```

Tehdään sitten testi kunnollisella salasanalla:

```ruby
  it "is saved with a proper password" do
    user = User.create username:"Pekka", password:"Secret1", password_confirmation:"Secret1"

    expect(user.valid?).to be(true)
    expect(User.count).to eq(1)
  end
```

Testin ensimmäinen "ekspektaatio" varmistaa, että luodun olion validointi onnistuu, eli että metodi <code>valid?</code> palauttaa true. Toinen ekspektaatio taas varmistaa, että tietokannassa olevien olioiden määrä on yksi.

Olisimme jälleen voineet käyttää käyttäjän validiteetin tarkastamiseen hieman luettavampaa muotoa

```ruby
    expect(user).to be_valid
```

On huomattavaa, että rspec **nollaa tietokannan aina ennen jokaisen testin ajamista**, eli jos teemme uuden testin, jossa tarvitaan Pekkaa, on se luotava uudelleen:

```ruby
  it "with a proper password and two ratings, has the correct average rating" do
    user = User.create username:"Pekka", password:"Secret1", password_confirmation:"Secret1"
    rating = Rating.new score:10
    rating2 = Rating.new score:20

    user.ratings << rating
    user.ratings << rating2

    expect(user.ratings.count).to eq(2)
    expect(user.average_rating).to eq(15.0)
  end
```

Kuten arvata saattaa, ei testin alustuksen (eli testattavan olion luomisen) toistaminen ole järkevää, ja yhteinen osa voidaan helposti eristää. Tämä tapahtuu esim. tekemällä samanlaisen alustuksen omaavalle osalle testeistä oma <code>describe</code>-lohko, jonka alkuun määritellään ennen jokaista testiä suoritettava <code>let</code>-komento, joka alustaa user-muuttujan uudelleen jokaista testiä ennen:

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  it "has the username set correctly" do
    user = User.new username:"Pekka"

    user.username.should == "Pekka"
  end

  it "is not saved without a password" do
    user = User.create username:"Pekka"

    expect(user).not_to be_valid
    expect(User.count).to eq(0)
  end

  describe "with a proper password" do
    let(:user){ User.create username:"Pekka", password:"Secret1", password_confirmation:"Secret1" }

    it "is saved" do
      expect(user).to be_valid
      expect(User.count).to eq(1)
    end

    it "and with two ratings, has the correct average rating" do
      rating = Rating.new score:10
      rating2 = Rating.new score:20

      user.ratings << rating
      user.ratings << rating2

      expect(user.ratings.count).to eq(2)
      expect(user.average_rating).to eq(15.0)
    end
  end
end
```

Siitä huolimatta, että muuttujan alustus on nyt vain yhdessä paikassa koodia, suoritetaan alustus uudelleen ennen jokaista metodia. Huom: metodi <code>let</code> suorittaa olion alustuksen vasta kun olioa tarvitaan oikeasti, tästä saatta joissain tilanteissa olla yllättäviä seurauksia!

Erityisesti vanhemmissa Rspec-testeissä näkee tyyliä, jossa testeille yhteinen alustus tapahtuu <code>before :each</code> -lohkon avulla. Tällöin testien yhteiset muuttujat on määriteltävä instanssimuuttujiksi, eli tyyliin <code>@user</code>.

Testien ja describe-lohkojen nimien valinta ei ole ollut sattumanvaraista. Määrittelemällä testauksen tulos formaattiin "documentation" (parametri -fd), saadaan testin tulos ruudulle mukavassa muodossa:

```ruby
$ rspec -fd spec

User
  has the username set correctly
  is not saved without a password
  with a proper password
    is saved
    and with two ratings, has the correct average rating

Finished in 0.12949 seconds (files took 1.95 seconds to load)
4 examples, 0 failures
```

Pyrkimyksenä onkin kirjoittaa testien nimet siten, että testit suorittamalla saadaan ohjelmasta mahdollisimman ihmisluettava "spesifikaatio".

Voit myös lisätä rivin ```-fd``` tiedostoon ```.rspec```, jolloin projektin rspec-testit näytetään aina documentation formaatissa.

**HUOM:** jos törmäät testiraportissasi ikävään varoitukseen

<pre>
[deprecated] I18n.enforce_available_locales will default to true in the future. If you really want to skip validation of your locale you can set I18n.enforce_available_locales = false to avoid this message.
</pre>

pääset siitä eroon lisäämällä tiedostoon spec/rails_helper.rb rivin

```ruby
    I18n.enforce_available_locales = false
```

> ## Tehtävä 1
>
> Lisää luokalle User testit, jotka varmistavat, että liian lyhyen tai pelkästään kirjaimista muodostetun salasanan omaavan käyttäjän luominen create-metodilla ei tallenna olioa tietokantaan, ja että luodun olion validointi ei ole onnistunut

Muista aina nimetä testisi niin että ajamalla Rspec dokumentointiformaatissa, saat kieliopillisesti järkevältä kuulostavan "speksin".

> ## Tehtävä 2
>
> Luo Rspecin generaattorilla (tai käsin) testipohja luokalle <code>Beer</code> ja tee testit, jotka varmistavat, että
> * oluen luonti onnistuu ja olut tallettuu kantaan jos oluella on nimi ja tyyli asetettuna
> * oluen luonti ei onnistu (eli creatella ei synny validia oliota), jos sille ei anneta nimeä
> * oluen luonti ei onnistu, jos sille ei määritellä tyyliä
>
> Jos jälkimmäinen testi ei mene läpi, laajenna koodiasi siten, että se läpäisee testin.
>
> Jos teet testitiedoston käsin, muista sijoittaa se hakemistoon spec/models

## Testiympäristöt eli fixturet

Edellä käyttämämme tapa, jossa testien tarvitsemia oliorakenteita luodaan testeissä käsin, ei ole välttämättä kaikissa tapauksissa järkevä. Parempi tapa on koota testiympäristön rakentaminen, eli testien alustamiseen tarvittava data omaan paikkaansa, "testifixtureen". Käytämme testien alustamiseen Railsin oletusarvoisen fixture-mekanismin sijaan FactoryGirl-nimistä gemiä, kts.
https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md

Lisätään Gemfileen seuraava

```ruby
group :test do
  gem 'factory_girl_rails'
end
```

ja päivitetään gemit komennolla <code>bundle install</code>

Tehdään fixtureja varten tiedosto spec/factories.rb ja kirjoitetaan sinne seuraava:

```ruby
FactoryGirl.define do
  factory :user do
    username "Pekka"
    password "Foobar1"
    password_confirmation "Foobar1"
  end

  factory :rating do
    score 10
  end

  factory :rating2, class: Rating do
    score 20
  end
end
```

Tiedostossa määritellään kolme "oliotehdasta". Ensimmäinen näistä on nimeltään user:

```ruby
  factory :user do
    username "Pekka"
    password "Foobar1"
    password_confirmation "Foobar1"
  end
```

Tehdasta voi käyttää luokan <code>User</code> olion luomiseen. Tehtaaseen ei tarvinnut määritellä erikseen tehtaan luomien olioiden luokkaa, sillä FactoryGirl päättelee sen suoraan käytettävän fixtuurin nimestä <code>user</code>.

Tiedostossa määritellään myös kaksi erinimistä reittausolioita generoivaa tehdasta <code>rating</code> ja <code>rating2</code>. FactoryGirl ei osaa päätellä näistä jälkimmäisen tyyppiä suoraan tehtaan nimestä, joten se on määriteltävä eksplisiittisesti.

Määriteltyjä tehtaita voidaan pyytää luomaan olioita seuraavasti:

```ruby
  user = FactoryGirl.create(:user)
  rating = FactoryGirl.create(:rating)
```

FactoryGirlin tehdasmetodin kutsuminen luo olion automaattisesti testausympäristön tietokantaan.

Muutetaan nyt testimme käyttämään FactoryGirliä.

```ruby
  describe "with a proper password" do
    let(:user){ FactoryGirl.create(:user) }

    it "is saved" do
      expect(user).to be_valid
      expect(User.count).to eq(1)
    end

    it "and with two ratings, has the correct average rating" do
      user.ratings << FactoryGirl.create(:rating)
      user.ratings << FactoryGirl.create(:rating2)

      expect(user.ratings.count).to eq(2)
      expect(user.average_rating).to eq(15.0)
    end
  end
```


Testi on nyt siistiytynyt jossain määrin.

Huom: samaa tehdasta voidaan pyytää luomaan useita oliota:

``` ruby
  r1 = FactoryGirl.create(:rating)
  r2 = FactoryGirl.create(:rating)
  r3 = FactoryGirl.create(:rating)
```

nyt luotaisiin kolme _eri_ olioa, jotka ovat kaikki samansisältöistä. Myös tehtaalta <code>user</code> voitaisiin pyytää kahta eri olioa. Tämä kuitenkin aiheuttaisi poikkeuksen, sillä <code>User</code>-olioiden validointi edellyttää, että username on yksikäsitteinen ja tehdas luo oletusarvoisesti aina "Pekka"-nimisen käyttäjän.

## Käyttäjän lempiolut, -panimo ja -oluttyyli

Toteutetaan seuraavaksi test driven -tyylillä (tai behaviour driven niinkuin rspecin luojat sanoisivat) käyttäjälle metodit, joiden avulla saadaan selville käyttäjän lempiolut, lempipanimo ja lempioluttyyli käyttäjän tekemien reittausten perusteella.

Oikeaoppisessa TDD:ssä ei tehdä yhtään koodia ennen kuin minimaalinen testi sen pakottaa. Tehdäänkin ensin testi, jonka avulla vaaditaan että <code>User</code>-olioilla on metodi <code>favorite_beer</code>:

```ruby
  it "has method for determining the favorite_beer" do
    user = FactoryGirl.create(:user)
    expect(user).to respond_to(:favorite_beer)
  end
```

Testi ei mene läpi, eli lisätään luokalle User metodin runko:

```ruby
class User < ActiveRecord::Base
  # ...

  def favorite_beer
  end
end
```

Testi menee nyt läpi. Lisätään seuraavaksi testi, joka varmistaa, että ilman reittauksia ei käyttäjllä ole mieliolutta, eli että metodi palauttaa nil:

```ruby
  it "without ratings does not have a favorite beer" do
    user = FactoryGirl.create(:user)
    expect(user.favorite_beer).to eq(nil)
  end
```

Testi menee läpi sillä Rubyssa metodit palauttavat oletusarvoisesti nil.

Refaktoroidaan testiä hieman lisäämällä juuri kirjoitetulle kahdelle testille oma <code>describe</code>-lohko

```ruby
  describe "favorite beer" do
    let(:user){FactoryGirl.create(:user) }

    it "has method for determining one" do
      expect(user).to respond_to(:favorite_beer)
    end

    it "without ratings does not have one" do
      expect(user.favorite_beer).to eq(nil)
    end
  end
```

Lisätään sitten testi, joka varmistaa että jos reittauksia on vain yksi, osaa metodi palauttaa reitatun oluen. Testiä varten siis tarvitsemme reittausolion lisäksi panimo-olion, johon reittaus liittyy. Laajennetaan ensin hieman fikstuureja, lisätään seuraavat:

```ruby
  factory :brewery do
    name "anonymous"
    year 1900
  end

  factory :beer do
    name "anonymous"
    brewery
    style "Lager"
  end
```

Koodi <code>create(:brewery)</code> luo panimon, jonka nimi on 'anonymous' ja perustamisvuosi 1900. Vastaavasti <code>create(:beer)</code> luo oluen, jonka tyyli on 'Lager' ja nimi 'anonymous' ja oluelle luodaan panimo, johon olut liittyy. Jos määrittelylohkossa ei olisi brewery:ä, tulisi oluen panimon arvoksi <code>nil</code> eli olut ei liittyisi mihinkään panimoon. Aiemmin määritelty <code>create(:rating)</code> luo reittausolion, jolle asetetaan scoreksi 10, mutta reittausta ei liitetä automaattisesti olueeseen eikä käyttäjään.

Voimme nyt luoda testissä FactoryGirlin avulla oluen (johon automaattisesti liittyy panimo) sekä reittauksen joka liittyy luotuun olueeseen ja käyttäjään:

```ruby
    it "is the only rated if only one rating" do
      beer = FactoryGirl.create(:beer)
      rating = FactoryGirl.create(:rating, beer:beer, user:user)

      # jatkuu...
    end
```

Alussa siis luodaan olut, sen jälkeen reittaus. Reittauksen <code>create</code>-metodille annetaan parametreiksi olut- ja käyttäjäoliot (joista molemmat on luotu FactoryGirlillä), joihin reittaus liitetään.

Luotu reittaus siis liittyy käyttäjään ja on käyttäjän ainoa reittaus. Testi siis lopulta odottaa, että reittaukseen liittyvä olut on käyttäjän lemipiolut:

```ruby
    it "is the only rated if only one rating" do
      beer = FactoryGirl.create(:beer)
      rating = FactoryGirl.create(:rating, beer:beer, user:user)

      expect(user.favorite_beer).to eq(beer)
    end
```

Testi ei mene läpi, sillä metodimme ei vielä tee mitään ja sen paluuarvo on siis aina <code>nil</code>.

Tehdään [TDD:n hengen mukaan](http://codebetter.com/darrellnorton/2004/05/10/notes-from-test-driven-development-by-example-kent-beck/) ensin "huijattu ratkaisu", eli ei vielä yritetäkään tehdä lopullista toimivaa versiota:

```ruby
class User < ActiveRecord::Base
  # ...

  def favorite_beer
    return nil if ratings.empty?   # palautetaan nil jos reittauksia ei ole
    ratings.first.beer             # palataan ensimmaiseen reittaukseen liittyvä olut
  end
end
```

Tehdään vielä testi, joka pakottaa meidät kunnollisen toteutuksen tekemiseen [(ks. triangulation)](http://codebetter.com/darrellnorton/2004/05/10/notes-from-test-driven-development-by-example-kent-beck/):

```ruby
    it "is the one with highest rating if several rated" do
      beer1 = FactoryGirl.create(:beer)
      beer2 = FactoryGirl.create(:beer)
      beer3 = FactoryGirl.create(:beer)
      rating1 = FactoryGirl.create(:rating, beer:beer1, user:user)
      rating2 = FactoryGirl.create(:rating, score:25,  beer:beer2, user:user)
      rating3 = FactoryGirl.create(:rating, score:9, beer:beer3, user:user)

      expect(user.favorite_beer).to eq(beer2)
    end
```

Ensin luodan kolme olutta ja sen jälkeen oluisiin sekä user-olioon liittyvät reittaukset. Ensimmäinen reittaus saa reittauksiin määritellyn oletuspisteytyksen eli 10 pistettä. Toiseen ja kolmanteen reittaukseen score annetaan parametrina.

Testi ei luonnollisesti mene vielä läpi, sillä metodin <code>favorite_beer</code> toteutus jätettiin aiemmin puutteelliseksi.

Muuta metodin toteutus nyt seuraavanlaiseksi:

```ruby
  def favorite_beer
    return nil if ratings.empty?
    ratings.sort_by{ |r| r.score }.last.beer
  end
```

eli ensin järjestetään reittaukset scoren perusteella, otetaan reittauksista viimeinen eli korkeimman scoren omaava ja palautetaan siihen liittyvä olut.

Koska järjestäminen perustui suoraan reittauksen attribuuttiin <code>score</code> oltaisiin metodin viimeinen rivi voitu kirjottaa myös hieman kompaktimmassa muodossa

```ruby
    ratings.sort_by(&:score).last.beer
```

Miten metodi itseasiassa toimiikaan? Suoritetaan operaatio konsolista:

```ruby
irb(main):020:0> u = User.first
irb(main):021:0> u.ratings.sort_by(&:score).last.beer
  Rating Load (0.2ms)  SELECT "ratings".* FROM "ratings" WHERE "ratings"."user_id" = ?  [["user_id", 1]]
  Beer Load (0.1ms)  SELECT "beers".* FROM "beers" WHERE "beers"."id" = ? ORDER BY "beers"."id" ASC LIMIT 1  [["id", 1]]
```

Seurauksena on 2 SQL-kyselyä, joista ensimmäinen

```ruby
SELECT "ratings".* FROM "ratings" WHERE "ratings"."user_id" = ?  [["user_id", 1]]
```

hakee kaikki käyttäjään liittyvät reittaukset tietokannasta. Reittausten järjestäminen tapahtuu keskusmuistissa. Jos käyttäjään liittyvien reittausten määrä olisi erittäin suuri, kannattaisi operaatio optimoida siten, että se tehtäisiin suoraan tietokantatasolla.

Tutkimalla dokumentaatiota (http://guides.rubyonrails.org/active_record_querying.html#ordering ja http://guides.rubyonrails.org/active_record_querying.html#limit-and-offset) päädymme seuraavaan ratkaisuun:

```ruby
  def favorite_beer
    return nil if ratings.empty?
    ratings.order(score: :desc).limit(1).first.beer
  end
```

Voimme konsolista käsin tarkastaa operaation tuloksena olevan SQL-kyselyn (huomaa, että metodi <code>to_sql</code>):

```ruby
irb(main):033:0> u.ratings.order(score: :desc).limit(1).to_sql
=> "SELECT  \"ratings\".* FROM \"ratings\"  WHERE \"ratings\".\"user_id\" = ?  ORDER BY \"ratings\".\"score\" DESC LIMIT 1"
```

Suorituskyvyn optimoinnissa kannattaa kuitenkin pitää maltti mukana ja sovelluksen kehitysvaiheessa ei vielä välttämättä kannata jäädä optimoimaan jokaista operaatiota.

## Testien apumetodit

Huomaamme, että testissä tarvittavien oluiden rakentamisen tekevä koodi on hieman ikävä. Voisimme konfiguroida FactoryGirliin oluita, joihin liittyy reittauksia. Päätämme kuitenkin tehdä testitiedoston puolelle reittauksellisen oluen luovan apumetodin <code>create_beer_with_rating</code>:

```ruby
    def create_beer_with_rating(user, score)
      beer = FactoryGirl.create(:beer)
      FactoryGirl.create(:rating, score:score, beer:beer, user:user)
      beer
    end
```

Apumetodia käyttämällä saamme siistityksi testiä

```ruby
    it "is the one with highest rating if several rated" do
      create_beer_with_rating(user, 10)
      best = create_beer_with_rating(user, 25)
      create_beer_with_rating(user, 7)

      expect(user.favorite_beer).to eq(best)
    end
```

Apumetodeja siis voi (ja kannattaa) määritellä rspec-tiedostoihin. Jos apumetodia tarvitaan ainoastaan yhdessä testitiedostossa, voi sen sijoittaa esim. tiedoston loppuun.

Parannetaan vielä edellistä hiukan määrittelemällä toinenkin metodi <code>create_beers_with_ratings</code>, jonka avulla on mahdollista luoda useita reitattuja oluita. Metodi saa reittaukset taulukon tapaan käyttäytyvän vaihtuvamittaisen parametrilistan (ks. http://www.ruby-doc.org/docs/ProgrammingRuby/html/tut_methods.html, kohta "Variable-Length Argument Lists") avulla:

```ruby
def create_beers_with_ratings(user, *scores)
  scores.each do |score|
    create_beer_with_rating(user, score)
  end
end
```

Kutsuttaessa metodia esim. seuraavasti

```ruby
    create_beers_with_ratings(user, 10, 15, 9)
```

tulee parametrin <code>scores</code> arvoksi kokoelma, jossa ovat luvut 10, 15 ja 9. Metodi luo (metodin <code>create_beer_with_rating</code> avulla) kolme olutta, joihin kuhunkin parametrina annetulla käyttäjällä on reittaus ja reittauksien pistemääriksi tulevat parametrin <code>scores</code> luvut.

Seuraavassa vielä koko mielioluen testaukseen liittyvä koodi:

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do

  # ..

  describe "favorite beer" do
    let(:user){FactoryGirl.create(:user) }

    it "has method for determining one" do
      user.should respond_to :favorite_beer
    end

    it "without ratings does not have one" do
      expect(user.favorite_beer).to eq(nil)
    end

    it "is the only rated if only one rating" do
      beer = create_beer_with_rating(user, 10)

      expect(user.favorite_beer).to eq(beer)
    end

    it "is the one with highest rating if several rated" do
      create_beers_with_ratings(user, 10, 20, 15, 7, 9)
      best = create_beer_with_rating(user, 25)

      expect(user.favorite_beer).to eq(best)
    end
  end

end # describe User

def create_beers_with_ratings(user, *scores)
  scores.each do |score|
    create_beer_with_rating user, score
  end
end

def create_beer_with_rating(user, score)
  beer = FactoryGirl.create(:beer)
  FactoryGirl.create(:rating, score:score,  beer:beer, user:user)
  beer
end
```

### FactoryGirl-troubleshooting

Kannattaa huomata, että jos määrittelet FactoryGirl-gemin testiympäristön lisäksi kehitysympäristöön, eli

```ruby
group :development, :test do
    gem 'factory_girl_rails'
    # ...
end
```

jos luot Railsin generaattorilla uusia resursseja, esim:

    rails g scaffold bar name:string

syntyy nyt samalla myös oletusarvoinen oliotehdas:

```ruby
mbp-18:ratebeer_temppi mluukkai$ rails g scaffold bar name:string
      ...
      invoke    rspec
      create      spec/models/bar_spec.rb
      invoke      factory_girl
      create        spec/factories/bars.rb
      ...
```

oletusarvoisen tehtaan sijainti ja sisältö on seuraava:

```ruby
mbp-18:ratebeer_temppi mluukkai$ cat spec/factories/bars.rb
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :bar do
    name "MyString"
  end
end
```

Tämä saattaa aiheuttaa yllättäviä tilanteita (jos määrittelet itse saman nimisen tehtaan, käytetään sen sijaan oletusarvoista tehdasta!), eli kannattanee määritellä gemi ainoastaan testausympäristöön luvun https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko4.md#testiymp%C3%A4rist%C3%B6t-eli-fixturet ohjeen tapaan.

Normaalisti rspec-tyhjentää tietokannan jokaisen testin suorituksen jälkeen. Tämä johtuu sitä, että oletusarvoisesti rspec suorittaa jokaisen testin transaktiossa, joka rollbackataan eli perutaan testin suorituksen jälkeen. Testit eivät siis todellisuudessa edes talleta mitään tietokantaan.

Joskus testeissä voi kuitenkin mennä kantaan pysyvästi olioita.

Oletetaan että testaisimme luokkaa <code>Beer</code> seuraavasti:

```ruby
  describe "when one beer exists" do
    beer = FactoryGirl.create(:beer)

    it "is valid" do
      expect(beer).to be_valid
    end

    it "has the default style" do
      expect(beer.style).to eq("Lager")
    end
  end
```

testin luoma <code>Beer</code>-olio menisi nyt pysyvästi testitietokantaan, sillä komento <code>FactoryGirl.create(:beer)</code>  ei ole minkään testin sisällä, eikä sitä siis suoriteta peruttavan transaktion aikana!

Testien ulkopuolelle, ei siis tule sijoittaa olioita luovaa koodia (poislukien testeistä kutsuttavat metodit). Olioiden luomisen on tapahduttava testikontekstissa, eli joko metodin <code>it</code> sisällä:

```ruby
  describe "when one beer exists" do
    it "is valid" do
      beer = FactoryGirl.create(:beer)
      expect(beer).to be_valid
    end

    it "has the default style" do
      beer = FactoryGirl.create(:beer)
      expect(beer.style).to eq("Lager")
    end
  end
```

komennon <code>let</code> tai <code>let!</code> sisällä:

```ruby
  describe "when one beer exists" do
    let(:beer){FactoryGirl.create(:beer)}

    it "is valid" do
      expect(beer).to be_valid
    end

    it "has the default style" do
      expect(beer.style).to eq("Lager")
    end
  end
```

tai hieman myöhemmin esiteltävissä <code>before</code>-lohkoissa.

Saat poistettua testikantaan vahingossa menneet oluet käynnistämällä konsolin testiympäristössä komennolla <code>rails c test</code>.

Validoinneissa määritellyt uniikkiusehdot saattavat joskus tuottaa yllätyksiä. Käyttäjän käyttäjätunnus on määritelty uniikisi, joten testi

```ruby
describe "the application" do
  it "does something with two users" do
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)

  # ...
  end
end
```

aiheuttaisi virheilmoituksen

```ruby
     Failure/Error: user2 = FactoryGirl.create(:user)
     ActiveRecord::RecordInvalid:
       Validation failed: Username has already been taken
```

sillä FactoryGirl yrittää nyt luoda kaksi käyttäjäolioa määritelmän

```ruby
  factory :user do
    username "Pekka"
    password "Foobar1"
    password_confirmation "Foobar1"
  end
```

perusteella, eli molemmille tulisi usernameksi 'Pekka'. Ongelma ratkeaisi antamalla toiselle luotavista oliosta joku muu nimi:

```ruby
describe "the application" do
  it "does something with two users" do
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user, username:"Arto")

  # ...
  end
end
```
Toinen vaihtoehto olisi määritellä FactoryGirlin käyttämät usernamet ns. sekvenssien avulla, ks.
https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md#sequences

Joskus validoinnin aiheuttama ongelma voi piillä syvemmällä.

Oletetaan että panimoiden nimet olisi määritelty uniikeiksi:

```ruby
class Brewery < ActiveRecord::Base
  validates :name, uniqueness: true

  #...
end
```

jos testissä luotaisiin nyt kaksi olutta

```ruby
describe "the application" do
  it "does something with two beers" do
    beer1 = FactoryGirl.create(:beer)
    beer2 = FactoryGirl.create(:beer)

  # ...
  end
end
```

olisi seurauksena virheilmoitus

```ruby
     Failure/Error: beer2 = FactoryGirl.create(:beer)
     ActiveRecord::RecordInvalid:
       Validation failed: Name has already been taken
```

Virheilmoitus on hieman hämäävä, sillä <code>Name has already been taken</code> viittaa nimenomaan olueeseen liittyvän _panimon_ nimeen!

Syy virheelle on seuraava. Oluttehdas on määritelty seuraavasti:

```ruby
  factory :beer do
    name "anonymous"
    brewery
    style "Lager"
  end
```

eli jokaista olutta kohti luodaan oletusarvoisesti _uusi_ panimo-olio, joka taas luodaan panimotehtaan perusteella:

```ruby
  factory :brewery do
    name "anonymous"
    year 1900
  end
```

eli _jokainen_ panimo saa nimekseen 'anonymous' ja jos panimon nimi on määritelty uniikiksi (mikä ei ole järkevää, sillä samannimisia panimoita voi olla useita) seuraa toista olutta luotaessa ongelma, koska oluen luomisen yhteydessä luotava panimo rikkoisi nimen yksikäsitteisyysehdon.

## testit ja debuggeri

Toivottavasti olet jo tässä vaiheessa kurssia rutinoitunut [byebugin](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#debuggeri) käyttäjä. Koska testitkin ovat normaalia ruby-koodia, on myös byebug käytettävissä sekä testikoodissa että testattavassa koodissa. Testausympäristön tietokannan tila saattaa joskus olla yllättävä, kuten edellä olevista esimerkeistä näimme. Ongelmatilanteissa kannattaa ehdottomasti pysäyttää testikoodi debuggerilla ja tutkia vastaako testattavien olioiden tila oletettua.

> ## Tehtävä 3
>
> ### Tämä ja seuraava tehtävä voivat olla jossain määrin haastavia. Tehtävien teko ei ole viikon jatkamisen kannalta välttämätöntä eli älä juutu tähän kohtaan. Voit tehdä tehtävät myös viikon muiden tehtävien jälkeen.
>
> Tee seuraavaksi TDD-tyylillä <code>User</code>-olioille metodi <code>favorite_style</code>, joka palauttaa tyylin, jonka oluet ovat saaneet käyttäjältä keskimäärin korkeimman reittauksen. Lisää käyttäjän sivulle tieto käyttäjän mielityylistä.
>
> Älä tee kaikkea yhteen metodiin (ellet ratkaise tehtävää tietokantatasolla ActiveRecordilla mikä sekin on mahdolista!), vaan määrittele sopivia apumetodeja! Jos huomaat metodisi olevan yli 5 riviä pitkä, teet asioita todennäköisesti joko liikaa tai liian kankeasti, joten refaktoroi koodiasi. Rubyn kokoelmissa on paljon tehtävään hyödyllisiä apumetodeja, ks. http://ruby-doc.org/core-2.2.0/Enumerable.html

> ## Tehtävä 4
>
> Tee vielä TDD-tyylillä <code>User</code>-olioille metodi <code>favorite_brewery</code>, joka palauttaa panimon, jonka oluet ovat saaneet käyttäjältä keskimäärin korkeimman reittauksen.  Lisää käyttäjän sivulle tieto käyttäjän mielipanimosta.
>
> Tee tarvittaessa apumetodeja rspec-tiedostoon, jotta testisi pysyvät siisteinä. Jos apumetodeista tulee samantapaisia, ei kannata copypasteta vaan yleistää ne.

Metodien <code>favorite_brewery</code> ja <code>favorite_style</code> tarvitsema toiminnallisuus on hyvin samankaltainen ja metodit ovatkin todennäköisesti enemmän tai vähemmän copy-pastea. Viikolla 5 tulee olemaan esimerkki koodin siistimisestä.

## Capybara

Siirrymme seuraavaksi järjestelmätason testaukseen. Kirjoitamme siis automatisoituja testejä, jotka käyttävät sovellusta normaalin käyttäjän tapaan selaimen kautta. De facto -tapa Rails-sovellusten selaintason testaamiseen on Capybaran https://github.com/jnicklas/capybara käyttö. Itse testit kirjoitetaan edelleen Rspecillä, capybara tarjoaa siis  rspec-testien käyttöön selaimen simuloinnin.

Lisätään Gemfileen (test-scopeen) gemit 'capybara' ja 'launchy' eli test-scopen pitäisi näyttää seuraavalta:

```ruby
group :test do
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'launchy'
end
```

Jotta gemit saadaan käyttöön, suoritetaan tuttu komento <code>bundle install</code>. Laitoksen koneilla saattaa komennon suorittamisessa kulua melko kauan, jopa 15 minuuttia.

**HUOM** jos bundle install ei toimi laitoksen koneella suorita ensin seuraava:

    gem install nokogiri -- --with-xml2-include=/usr/include/libxml2/libxml/ --with-xml2-lib=/usr/lib  --with-xslt-include=/usr/include/libxslt --with-xslt-lib=/usr/lib


Tiedoston  spec/rails_helper.rb-tiedoston yläosaan on myös lisättävä rivi

    require 'capybara/rspec'

Nyt olemme valmiina ensimmäiseen selaintason testiin.

Selaintason testit on tapana sijoittaa hakemistoon _spec/features_. Yksikkötestit organisoidaan useimmiten siten, että kutakin luokkaa testaavat testit tulevat omaan tiedostoonsa. Ei ole aina itsestään selvää, miten selaimen kautta suoritettavat käyttäjätason testit kannattaisi organisoida. Yksi vaihtoehto on käyttää kontrollerikohtaisia tiedostoja, toinen taas jakaa testit eri tiedostoihin järjestelmän eri toiminnallisuuksien mukaan.

Aloitetaan testien määrittely panimoihin liittyvästä toiminnallisuudesta, luodaan tiedosto spec/features/breweries_page_spec.rb:

```ruby
require 'rails_helper'

describe "Breweries page" do
  it "should not have any before been created" do
    visit breweries_path
    expect(page).to have_content 'Listing breweries'
    expect(page).to have_content 'Number of breweries: 0'
  end
end
```

Testi aloittaa navigoimalla <code>visit</code>-metodia käyttäen panimoiden listalle. Kuten huomaamme, Railsin polkuapumetodit ovat myös Rspec-testien käytössä. Tämän jälkeen tarkastetaan sisältääkö renderöity sivu tekstin 'Listing breweries' ja tiedon siitä että panimoiden lukumäärä on 0 eli tekstin 'Number of breweries: 0'. Capybara asettaa sen sivun, jolla testi kulloinkin on muuttujaan <code>page</code>.

Testejä tehdessä tulee (erittäin) usein tilanteita, joissa olisi hyödyllistä nähdä <code>page</code>-muuttujan kuvaaman sivun html-muotoinen lähdekoodi. Tämä onnistuu lisäämällä testiin komento <code>puts page.html</code>

Toinen vaihoehto on lisätä testiin komento <code>save_and_open_page</code>, joka tallettaa ja avaa kyseisen sivun oletusselaimessa. Linuxissa joudut määrittelemään selaimen oletusselaimeksi <code>BROWSER</code>-ympäristömuuttujan avulla.  Esim. laitoksen koneilla saat määriteltyä oletusselaimeksi chromiumin komennolla:

    export BROWSER='/usr/bin/chromium-browser'

Määrittely on voimassa vain siinä shellissä jossa teet sen. Jos haluat määrittelystä pysyvän, lisää se tiedostoon ~/.bashrc

Suorita nyt testi tuttuun tapaan komennolla <code>rspec spec</code>. Jos haluat ajaa ainoastaan nyt määritellyn testin, muista että voit rajata suoritettavat testit antamalla komennon esim. muodossa

    rspec spec/features/breweries_page_spec.rb

Testi ei todennäköisesti mene läpi. Selvitä mistä vika johtuu ja korjaa testi tai sivulla oleva teksti. Komennon <code>save_and_open_page</code> käyttö on suositeltavaa!

Lisätään testi, joka testaa tilannetta, jossa tietokannassa on 3 panimoa:

```ruby
  it "lists the existing breweries and their total number" do
    breweries = ["Koff", "Karjala", "Schlenkerla"]
    breweries.each do |brewery_name|
      FactoryGirl.create(:brewery, name:brewery_name)
    end

    visit breweries_path

    expect(page).to have_content "Number of breweries: #{breweries.count}"

    breweries.each do |brewery_name|
      expect(page).to have_content brewery_name
    end
  end
```

Lisätään vielä testi, joka tarkastaa, että panimoiden sivulta pääsee linkkiä klikkaamalla yksittäisen panimon sivulle. Hyödynnämme tässä capybaran metodia <code>click_link</code>, jonka avulla on mahdollista klikata sivulla olevaa linkkiä:

```ruby
  it "allows user to navigate to page of a Brewery" do
    breweries = ["Koff", "Karjala", "Schlenkerla"]
    year = 1896
    breweries.each do |brewery_name|
      FactoryGirl.create(:brewery, name: brewery_name, year: year += 1)
    end

    visit breweries_path

    click_link "Koff"

    expect(page).to have_content "Koff"
    expect(page).to have_content "Established at 1897"
  end
```

Testi menee läpi olettaen että sivulla käytetty kirjoitusasu on sama kuin testissä. Ongelmatilanteissa testiin kannattaa lisätä komento <code>save_and_open_page</code> ja varmistaa visuaalisesti testin avaaman sivun sisältö.

Kahdessa viimeisessä testissämme on sama alkuosa, eli aluksi luodaan kolme panimoa ja navigoidaan panimojen sivulle.

Seuraavassa vielä refaktoroitu lopputulos, jossa yhteisen alustuksen omaavat testit on siirretty omaan describe-lohkoon, jolle on määritelty <code>before :each</code> -lohko alustusta varten.

```ruby
require 'rails_helper'

describe "Breweries page" do
  it "should not have any before been created" do
    visit breweries_path
    expect(page).to have_content 'Listing breweries'
    expect(page).to have_content 'Number of breweries: 0'

  end

  describe "when breweries exists" do
    before :each do
      @breweries = ["Koff", "Karjala", "Schlenkerla"]
      year = 1896
      @breweries.each do |brewery_name|
        FactoryGirl.create(:brewery, name: brewery_name, year: year += 1)
      end

      visit breweries_path
    end

    it "lists the breweries and their total number" do
      expect(page).to have_content "Number of breweries: #{@breweries.count}"
      @breweries.each do |brewery_name|
        expect(page).to have_content brewery_name
      end
    end

    it "allows user to navigate to page of a Brewery" do
      click_link "Koff"

      expect(page).to have_content "Koff"
      expect(page).to have_content "Established at 1897"
    end

  end
end
```

Huomaa, että describe-lohkon sisällä oleva <code>before :each</code> suoritetaan kertaalleen ennen jokaista describen alla määriteltyä testiä ja **jokainen testi alkaa tilanteesta, missä tietokanta on tyhjä**.

## Käyttäjän toiminnallisuuden testaaminen

Siirrytään käyttäjän toiminnallisuuteen, luodaan tätä varten tiedosto features/users_spec.rb. Aloitetaan testillä, joka varmistaa, että käyttäjä pystyy kirjautumaan järjestelmään:

```ruby
require 'rails_helper'

describe "User" do
  before :each do
    FactoryGirl.create :user
  end

  describe "who has signed up" do
    it "can signin with right credentials" do
      visit signin_path
      fill_in('username', with:'Pekka')
      fill_in('password', with:'Foobar1')
      click_button('Log in')

      expect(page).to have_content 'Welcome back!'
      expect(page).to have_content 'Pekka'
    end
  end
end
```

Testi demonstroi lomakkeen kanssa käytävää interaktiota, komento <code>fill_in</code> etsii lomakkeesta id-kentän perusteella tekstikenttää, jolle se syöttää parametrina annetun arvon. <code>click_button</code> toimii kuten arvata saattaa, eli painaa sivulta etsittävää painiketta.

Huomaa, että testissä on <code>before :each</code>-lohko, joka luo ennen jokaista testiä FactoryGirliä käyttäen User-olion. Ilman olion luomista kirjautuminen ei onnistuisi, sillä tietokanta on jokaiseen testin suoritukseen lähdettäessä tyhjä.

Capybaran dokumentaation kohdasta the DSL ks. https://github.com/jnicklas/capybara#the-dsl löytyy lisää esimerkkejä mm. sivulla olevien elementtien etsimiseen ja esim. lomakkeiden käyttämiseen.

Tehdään vielä muutama testi käyttäjälle. Virheellisen salasanan syöttämisen pitäisi ohjata takaisin kirjaantumissivulle:

```ruby
  describe "who has signed up" do
    # ...

    it "is redirected back to signin form if wrong credentials given" do
      visit signin_path
      fill_in('username', with:'Pekka')
      fill_in('password', with:'wrong')
      click_button('Log in')

      expect(current_path).to eq(signin_path)
      expect(page).to have_content 'Username and/or password mismatch'
    end
  end
```

Testi hyödyntää metodia <code>current_path</code>, joka palauttaa sen polun minne testin suoritus on metodin kutsuhetkellä päätynyt. Metodin avulla varmistetaan, että käyttäjä uudelleenohjataan takaisin kirjautumissivulle epäonnistuneen kirjautumisen jälkeen.

Ei ole aina täysin selvää missä määrin sovelluksen bisneslogiikkaa kannattaa testata selaintason testien kautta. Edellä tekemämme käyttäjä-olion suosikkioluen, panimon ja oluttyylin selvittävien logiikoiden testaaminen on ainakin viisainta tehdä yksikkötesteinä.

Käyttäjätason testein voidaan esim. varmistua, että sivuilla näkyy sama tilanne, joka tietokannassa on, eli esim. panimoiden sivun testissä tietokantaan generoitiin 3 panimoa ja sen jälkeen testattiin että ne kaikki renderöityvät panimoiden listalle.

Myös sivujen kautta tehtävät lisäykset ja poistot kannattaa testata. Esim. seuraavassa testataan, että uuden käyttäjän rekisteröityminen lisää järjestelmän käyttäjien lukumäärää yhdellä:

```ruby
  it "when signed up with good credentials, is added to the system" do
    visit signup_path
    fill_in('user_username', with:'Brian')
    fill_in('user_password', with:'Secret55')
    fill_in('user_password_confirmation', with:'Secret55')

    expect{
      click_button('Create User')
    }.to change{User.count}.by(1)
  end
```

Huomaa, että lomakkeen kentät määriteltiin <code>fill_in</code>-metodeissa hieman eri tavalla kuin kirjautumislomakkeessa. Kenttien id:t voi ja kannattaa aina tarkastaa katsomalla sivun lähdekoodia selaimen _view page source_ -toiminnolla.

Testi siis odottaa, että _Create user_ -painikkeen klikkaaminen muuttaa tietokantaan talletettujen käyttäjien määrää yhdellä. Syntaksi on hieno, mutta kestää hetki ennen kuin koko Rspecin ilmaisuvoimainen kieli alkaa tuntua tutulta.

Pienenä detaljina kannattaa huomioida, että metodille <code>expect</code> voi antaa parametrin kahdella eri tavalla.
Jos metodilla testaa jotain arvoa, annetaan testattava arvo suluissa esim <code>expect(current_path).to eq(signin_path)</code>. Jos sensijaan testataan jonkin operaation (esim. edellä <code>click_button('Create User')</code>) vaikutusta jonkun sovelluksen olion (<code>User.count</code>) arvoon, välitetään suoritettava operaatio koodilohkona <code>expect</code>ille.

Lue aiheesta lisää Rspecin dokumentaatiosta https://www.relishapp.com/rspec/rspec-expectations/v/2-14/docs/built-in-matchers

Edellinen testi siis testasi, että selaimen tasolla tehty operaatio luo olion tietokantaan. Onko vielä tehtävä erikseen testi, joka testaa että luodulla käyttäjätunnuksella voi kirjautua järjestelmään? Kenties, edellinen testihän ei ota kantaa siihen tallentuiko käyttäjäolio tietokantaan oikein.

Potentiaalisia testauksen kohteita on kuitenkin niin paljon, että kattava testaus on mahdotonta ja testejä tulee pyrkiä ensisijaisesti kirjoittamaan niille asioille, jotka ovat riskialttiita hajoamaan.

Tehdään vielä testi oluen reittaamiselle. Tehdään testiä varten oma tiedosto spec/features/ratings_spec.rb

```ruby
require 'rails_helper'

describe "Rating" do
  let!(:brewery) { FactoryGirl.create :brewery, name:"Koff" }
  let!(:beer1) { FactoryGirl.create :beer, name:"iso 3", brewery:brewery }
  let!(:beer2) { FactoryGirl.create :beer, name:"Karhu", brewery:brewery }
  let!(:user) { FactoryGirl.create :user }

  before :each do
    visit signin_path
    fill_in('username', with:'Pekka')
    fill_in('password', with:'Foobar1')
    click_button('Log in')
  end

  it "when given, is registered to the beer and user who is signed in" do
    visit new_rating_path
    select('iso 3', from:'rating[beer_id]')
    fill_in('rating[score]', with:'15')

    expect{
      click_button "Create Rating"
    }.to change{Rating.count}.from(0).to(1)

    expect(user.ratings.count).to eq(1)
    expect(beer1.ratings.count).to eq(1)
    expect(beer1.average_rating).to eq(15.0)
  end
end
```

Testi rakentaa käyttämänsä panimon, kaksi olutta ja käyttäjän metodin <code>let!</code> aiemmin käyttämämme metodin <code>let</code> sijaan. Näin toimitaan siksi että huutomerkitön versio ei suorita operaatiota välittömästi vaan vasta siinä vaiheessa kun koodi viittaa olioon eksplisiittisesti. Olioon <code>beer1</code> viitataan koodissa vasta lopun tarkastuksissa, eli jos olisimme luoneet sen metodilla <code>let</code> olisi reittauksen luomisvaiheessa tullut virhe, sillä olut ei olisi vielä ollut kannassa, eikä vastaavaa select-elementtiä olisi löytynyt.


Testin <code>before</code>-lohkossa on koodi, jonka avulla käyttäjä kirjautuu järjestelmään. On todennäköistä, että samaa koodilohkoa tarvitaan useissa eri testitiedostoissa. Useassa eri paikassa tarvittava testikoodi kannattaa eristää omaksi apumetodikseen ja sijoittaa moduuliin, jonka kaikki sitä tarvitsevat testitiedostot voivat sisällyttää itseensä. Luodaan moduli <code>Helper</code>hakemistoon _spec_ sijoitettavaan tiedostoon _helpers.rb_ ja siirretään kirjautumisesta vastaava koodi sinne:

```ruby
module Helpers

  def sign_in(credentials)
    visit signin_path
    fill_in('username', with:credentials[:username])
    fill_in('password', with:credentials[:password])
    click_button('Log in')
  end
end
```

Metodi <code>sign_in</code> saa siis käyttäjätunnus/salasanaparin parametrikseen hashina.

Lisätään tiedostoon *rails_helper.rb* heti muiden require-komentojen jälkeen rivi

    require 'helpers'

Voimme ottaa modulin määrittelemän metodi käyttöön testeissä komennolla <code>include Helper</code>:

```ruby
require 'rails_helper'

include Helpers

describe "Rating" do
  let!(:brewery) { FactoryGirl.create :brewery, name:"Koff" }
  let!(:beer1) { FactoryGirl.create :beer, name:"iso 3", brewery:brewery }
  let!(:beer2) { FactoryGirl.create :beer, name:"Karhu", brewery:brewery }
  let!(:user) { FactoryGirl.create :user }

  before :each do
    sign_in(username:"Pekka", password:"Foobar1")
  end
```

ja

```ruby
require 'rails_helper'

include Helpers

describe "User" do
  before :each do
    FactoryGirl.create :user
  end

  describe "who has signed up" do
    it "can signin with right credentials" do
      sign_in(username:"Pekka", password:"Foobar1")

      expect(page).to have_content 'Welcome back!'
      expect(page).to have_content 'Pekka'
    end

    it "is redirected back to signin form if wrong credentials given" do
      sign_in(username:"Pekka", password:"wrong")

      expect(current_path).to eq(signin_path)
      expect(page).to have_content 'username and password do not match'
    end
  end

  it "when signed up with good credentials, is added to the system" do
    visit signup_path
    fill_in('user_username', with:'Brian')
    fill_in('user_password', with:'Secret55')
    fill_in('user_password_confirmation', with:'Secret55')

    expect{
      click_button('Create User')
    }.to change{User.count}.by(1)
  end
end
```

Kirjautumisen toteutuksen siirtäminen apumetodiin siis kasvattaa myös testien luettavuutta, ja jos kirjautumissivun toiminnallisuus myöhemmin muuttuu, on testien ylläpito helppoa, koska muutoksia ei tarvita kuin yhteen kohtaan.

> ## Tehtävä 5
>
> Tee testi, joka varmistaa, että järjestelmään voidaan lisätä www-sivun kautta olut, jos oluen nimikenttä saa validin arvon (eli se on epätyhjä). Tee myös testi, joka varmistaa, että selain näyttää asiaan kuuluvan virheilmoituksen jos oluen nimi ei ole validi, ja että tälläisessä tapauksessa tietokantaan ei talletu mitään.
>
> **HUOM:** ohjelmassasi on ehkä bugi tilanteessa, jossa yritetään luoda epävalidin nimen omaava olut. Kokeile toiminnallisuutta selaimesta. Syynä tälle on selitetty viikon alussa, kohdassa https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko4.md#muutama-huomio. Korjaa vika koodistasi.
>
> Muista ongelmatilanteissa komento <code>save_and_open_page</code>!


> ## Tehtävä 6
>
> Tee testi joka varmistaa, että tietokannassa olevat reittaukset ja niiden lukumäärä näytetään sivulla _ratings_. Jos lukumäärää ei toteutuksessani näytetä, korjaa puute.
>
> **Vihje**: voit tehdä testin esim. siten, että luot aluksi FactoryGirlillä reittauksia tietokantaan. Tämän jälkeen voit testata capybaralla sivun ratings sisältöä.
>
> Muista ongelmatilanteissa komento <code>save_and_open_page</code>!


> ## Tehtävä 7
>
> Tee testi joka varmistaa, että käyttäjän reittaukset näytetään käyttäjän sivulla. Käyttäjän sivulla tulee siis näkyä kaikki käyttäjän omat muttei muiden käyttäjien tekemiä reittauksia.
>
> Huomaa, että navigoidessasi käyttäjän <code>user</code> sivulle, joudut antamaan metodille <code>visit</code> polun määritteleväksi parametriksi <code>user_path(user)</code>, eli yleensä käytetty lyhempi  muoto (olio itse) ei capybaran kanssa toimi.

> ## Tehtävä 8
>
>  Tee testi, joka varmistaa että käyttäjän poistaessa oma reittauksensa, se poistuu tietokannasta.
>
> Jos sivulla on useita linkkejä joilla on sama nimi, ei <code>click_link</code> toimi. Joudut tälläisissä tilanteissa yksilöimään mikä linkeistä valitaan, ks. http://rubydoc.info/github/jnicklas/capybara/master/Capybara/Node/Finders ja esim. [tämä](http://stackoverflow.com/questions/6733427/how-to-click-on-the-second-link-with-the-same-text-using-capybara-in-rails-3)


> ## Tehtävä 9
>
> Jos teit tehtävät 3-4, laajenna käyttäjän sivua siten, että siellä näytetään käyttäjän lempioluttyyli sekä lempipanimo. Tee ominaisuudelle myös capybara-testit. Monimutkaista laskentaa testeissä ei kannata testata, sillä yksikkötestit varmistavat toiminnallisuuden jo riittävissä määrin.

## RSpecin syntaksin uudet tuulet

Kuten kirjoittaessamme ensimmäistä testiä totesimme, on Rspecissä useita tapoja saman asian ilmaisemiseen. Tehdään nyt muutama yksikkötesti Brewery-modelille. Aloitetaan generoimalla testipohja komennolla

    rails generate rspec:model brewery

Kirjoitetaan ensin "vanhahtavalla", nyt jo deprekoidulla <code>should</code>-syntaksilla (ks. https://github.com/rspec/rspec-expectations/blob/master/Should.md) testi, joka varmistaa että <code>create</code> asettaa panimon nimen ja perustamisvuoden oikein, ja että olio tallettuu kantaan:

```ruby
require 'rails_helper'

RSpec.describe Brewery, type: :model do
  it "has the name and year set correctly and is saved to database" do
    brewery = Brewery.create name:"Schlenkerla", year:1674

    brewery.name.should == "Schlenkerla"
    brewery.year.should == 1674
    brewery.valid?.should == true
  end
end
```

Viimeinen ehto, eli onko panimo validi ja tallentunut kantaan on ilmaistu kömpelösti. Koska panimon metodi <code>valid?</code> palauttaa totuusarvon, voimme ilmaista asian myös seuraavasti (ks http://rubydoc.info/gems/rspec-expectations/RSpec/Matchers):

```ruby
  it "has the name and year set correctly and is saved to database" do
    brewery = Brewery.create name:"Schlenkerla", year:1674

    brewery.name.should == "Schlenkerla"
    brewery.year.should == 1674
    brewery.should be_valid
  end
```

Käytettäessä <code>be_something</code> predikaattimatcheria, rspec olettaa, että oliolla on totuusarvoinen metodi nimeltään <code>something?</code>, eli kyse on konventioiden avulla aikaansaadusta "magiasta".

Ilmaisu <code>brewery.should be_valid</code> on lähempänä luonnollista kieltä, joten se on ehdottomasti suositeltavampi. Testi, joka testaa että panimoa ei voida tallettaa ilman nimeä voidaan tehdä seuraavasti käyttäen shouldin negaatiota eli metodia <code>should_not</code>:

```ruby
  it "without a name is not valid" do
    brewery = Brewery.create  year:1674

    brewery.should_not be_valid
  end
```

Myös muoto <code>brewery.should be_invalid</code> toimisi täsmälleen samoin.

Käytimme yllä shouldin sijaan <code>expect</code>-syntaksia (ks. http://rubydoc.info/gems/rspec-expectations/) joka on vallannut alaa shouldilta (vuonna 2010 Rspecin kehittäjien kirjoittamassa kirjassa http://pragprog.com/book/achbd/the-rspec-book käytetään vielä lähes yksinomaan shouldia!). Testimme expectillä olisi seuraava:

```ruby
  it "has the name and year set correctly and is saved to database" do
    brewery = Brewery.create name:"Schlenkerla", year:1674

    expect(brewery.name).to eq("Schlenkerla")
    expect(brewery.year).to eq(1674)
    expect(brewery).to be_valid
  end

  it "without a name is not valid" do
    brewery = Brewery.create  year:1674

    expect(brewery).not_to be_valid
  end
```

Voisimme kirjoittaa rivin <code>expect(brewery.year).to eq(1674)</code> myös muodossa <code>expect(brewery.year).to be(1674)</code> sen sijaan <code>expect(brewery.name).to be("Schlenkerla")</code> ei toimisi, virheilmoitus antaakin vihjeen mistä on kysymys:

```ruby
  1) Brewery has the name and year set correctly and is saved to database
     Failure/Error: expect(brewery.name).to be("Schlenkerla")

       expected #<String:44715020> => "Schlenkerla"
            got #<String:47598800> => "Schlenkerla"

       Compared using equal?, which compares object identity,
       but expected and actual are not the same object. Use
       `expect(actual).to eq(expected)` if you don't care about
       object identity in this example.
```

Eli <code>be</code> vaatii että kysessä ovat samat oliot, pelkkä olioiden samansisältöisyys ei riitä, kokonaislukuolioita, joiden suuruus on 1674 on Rubyssä vaan yksi, sen takia be toimii vuoden yhteydessä, sen sijaan merkkijonoja joiden sisältö on "Schlenkerla" voi olla mielivaltaisen paljon, eli merkkijonoja vertailtaessa on käytettävä matcheria <code>eq</code>.

Testiä on mahdollisuus vielä hioa käyttämällä Rspec 2:n (https://www.relishapp.com/rspec/rspec-core/v/2-11/docs) mukanaan tuomaa syntaksia. Jokaisessa testimme ehdossa _testauksen kohde_ on sama, eli muuttujaan <code>brewery</code> talletettu olio. Uusi <code>subject</code> syntaksi mahdollistaakin sen, että testauksen kohde määritellään vain kerran, ja sen jälkeen siihen ei ole tarvetta viitata eksplisiittisesti. Seuraavassa testi uudelleenmuotoiltuna uutta syntaksia käyttäen:

```ruby
  describe "when initialized with name Schlenkerla and year 1674" do
    subject{ Brewery.create name: "Schlenkerla", year: 1674 }

    it { should be_valid }
    its(:name) { should eq("Schlenkerla") }
    its(:year) { should eq(1674) }
  end
```

Testi on entistä kompaktimpi ja luettavuudeltaan erittäin sujuva. Mikä parasta, myös dokumenttiformaatissa generoitu testiraportti on hyvin luonteva:

```ruby
$ rspec spec/models/brewery_spec.rb -fd

Brewery
  without a name is not valid
  when initialized with name Schlenkerla and year 1674
    should be valid
    name
      should eq "Schlenkerla"
    year
      should eq 1674

Finished in 0.03309 seconds
```

**Huom:** <code>its</code>-syntaksi ei ole Rspecin versiosta 3 lähtien enää rspec-coressa ja toimiakseen se vaatii seuraavan gemin asentamsen:

    gem 'rspec-its'

Lisää subject-syntaktista osoitteessa
https://www.relishapp.com/rspec/rspec-core/v/2-11/docs/subject

Neuvoja hyvän Rspecin kirjoittamiseen antaa myös sivu
http://betterspecs.org/

## Testauskattavuus

Testien rivikattavuus (line coverage) mittaa kuinka monta prosenttia ohjelman koodiriveistä tulee suoritettua testien suorituksen yhteydessä. Rails-sovelluksen testikattavuus on helppo mitata _simplecov_-gemin avulla, ks. https://github.com/colszowka/simplecov

Gem otetaan käyttöön lisäämällä Gemfilen test -scopeen rivi

    gem 'simplecov', require: false

**Huom** normaalin <code>bundle install</code>-komennon sijaan saatat joutua antamaan tässä vaiheessa komennon <code>bundle update</code>, jotta kaikista gemeistä saatiin asennetuiksi yhteensopivat versiot.

Jotta simplecov saadaan käyttöön tulee tiedoston rails_helper.rb alkuun, **kahdeksi ensimmäiseksi riviksi** lisätä seuraavat:

```ruby
require 'simplecov'
SimpleCov.start('rails')
```

Sitten ajetaan testit (ongelmatilanteessa ks. ylempi huomautus)

```ruby
$ rspec spec
.....................................

Finished in 1.52 seconds (files took 1.93 seconds to load)
37 examples, 0 failures

Coverage report generated for RSpec to /Users/mluukkai/kurssirepot/ratebeer/coverage. 156 / 357 LOC (43.7%) covered.
```

Testien rivikattavuus on siis 43.7 prosenttia. Tarkempi raportti on nähtävissä avaamalla selaimella tiedosto coverage/index.html. Kuten kuva paljastaa, on suuria osia ohjelmasta, erityisesti kontrollereista vielä erittäin huonosti testattu:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w4-1.png)

Suurikaan rivikattavuus ei tietysti vielä takaa että testit testaavat järkeviä asioita. Helposti mitattavana metriikkana se on kuitenkin parempi kuin ei mitään ja näyttää ainakin ilmeisimmät puutteet testeissä.

> ## Tehtävä 10
>
> Ota simplecov käyttöön ohjelmassasi. Tutki raportista (klikkaamalla punaisella tai keltaisella merkittyjä luokkia) mitä rivejä koodissasi on vielä täysin testaamatta.

## Jatkuva integraatio

[Jatkuvalla integraatiolla](http://martinfowler.com/articles/continuousIntegration.html) (engl. continuous integration) tarkoitetaan käytännettä, jossa ohjelmistokehittäjät integroivat koodin tekemänsä muutokset yhteiseen kehityshaaraan mahdollisimman usein. Periaatteena on pitää ohjelman kehitysversio koko ajan toimivana eliminoiden näin raskas erillinen integrointivaihe. Toimiakseen jatkuva integraatio edellyttää kattavaa automaattisten testien joukkoa. Yleensä jatkuvan integraation yhteydessä käytetään keskitettyä palvelinta, joka tarkkailee repositorioa, jolla kehitysversio sijaitsee. Kun kehittäjä integroi koodin kehitysversioon, integraatiopalvelin huomaa muutoksen, buildaa koodin ja ajaa testit. Jos testit eivät mene läpi, tiedottaa integraatiopalvelin tästä tavalla tai toisella asianomaisia.

Travis https://travis-ci.org/ on SaaS (software as a service) -periaatteella toimiva jatkuvan integraation palvelu, joka on noussut nopeasti suosituksi Open Source -projektien käytössä.

Githubissa olevat Rails-projektit on helppo asettaa Travisin tarkkailtavaksi.

> ## Tehtävä 11
>
> Tee repositorion juureen Travisia varten konfiguraatiotiedosto .travis.yml (HUOM! Kohtaan ```rvm:``` aseta käyttämäsi rubyn versio.) jolla on seuraava sisältö:
>
>```ruby
>language: ruby
>
>rvm:
>  - 2.3.0
>
>script:
>  - bundle exec rake db:migrate --trace
>  - RAILS_ENV=test bundle exec rake db:migrate --trace
>  - bundle exec rake db:test:prepare
>  - bundle exec rspec -fd spec/
>```
>
>Klikkaa sitten Travisin sivulta linkkiä "sign in with github" ja anna tunnuksesi.
>
>Mene oikeassa ylänurkassa olevan nimesi kohdalle ja valitse "accounts". Kytke avautuvasta näkymästä ratebeer-repositoriosi jatkuva integraatio päälle.
>
>Kun seuraavan kerran pushaat koodia githubiin, suorittaa Travis automaattisesti buildausskriptin, joka siis määrittelee testit suoritettaviksi. Saat sähköpostitse tiedotuksen jos buildin status muuttuu.
>
>Lisää repositoriosi README.md-tiedostoon (**huom:** tiedoston päätteen on oltava md!) linkki sovelluksen TravisCI-sivulle:
>
>```ruby
>[![Build Status](https://travis-ci.org/mluukkai/ratebeer-public.png)](https://travis-ci.org/mluukkai/ratebeer-public)
>```
> Huomaa, että linkin loppuosa on sama kun projektisi Github-repositorion, edellinen siis liittyy Github-repoon https://github.com/mluukkai/ratebeer-public
>
>Näin kaikki asianosaiset näkevät sovelluksen tilan ja todennäköisyys ettei sovelluksen testejä rikota kasvaa!

## Continuous delivery

Jatkuvaa integraatiota vielä askeleen eteenpäin viety käytäntö on jatkuva toimittaminen eng. continuous delivery http://en.wikipedia.org/wiki/Continuous_delivery jonka yhtenä osatekijänä on jatkuva deployaus, eli idea, jonka mukaan sovelluksen uusin versio aina integroimisen yhteydessä myös deployataan eli käynnistetään tuotantoympäristön kaltaiseen ympäristöön tai parhaassa tapauksessa suoraan tuotantoon.

Eriyisesti Web-sovellusten yhteydessä jatkuva deployaaminen saattaa olla hyvinkin vaivaton operaatio.

> ## Tehtävä 12
>
> Toteuta sovelluksellesi jatkuva deployaaminen Herokuun Travis-CI:n avulla. Konfiguroi myös migraatiot suoritettavaksi depolymentin yhteydessä
>
> Ks. ohjeita seuraavista
http://about.travis-ci.org/docs/user/deployment/heroku/
ja http://about.travis-ci.org/blog/2013-07-09-introducing-continuous-deployment-to-heroku/
>
> **HUOM** on erittäin suositeltavaa että teet konfiguroinnin [travisin komentorivityökalun](http://blog.travis-ci.com/2013-01-14-new-client/) avulla! Huomaa, että asennuksen jälkeen joudut uudelleenkäynnistämään konsolin.
>
> **HUOM2:**  Travisin ja Herokun yhteistoiminnallisuudessa on ilmennyt aika-ajoin ongelmia. Tutki tarkkaan virheilmoituksia ja jos et keksi mikä on vikana, kokeile deployaamista jonkin ajan (esim. muutaman tunnin) kuluttua uudelleen. Älä siis juutu tähän kohtaan!

## Koodin laatumetriikat

Testauskattavuuden lisäksi myös koodin laatua kannattaa valvoa. SaaS-palveluna toimivan Codeclimaten https://codeclimate.com avulla voidaan generoida Rails-koodista erilaisia laatumetriikoita.

> ## Tehtävä 13
>
>Codeclimate on ilmainen opensource-projekteille. Rekisteröi projektisi sivulta https://codeclimate.com/pricing löytyvän hieman huomaamattoman linkin "Add an OS repo" avulla.
>
>Codeclimate valittelee hiukan koodissa olevasta samanlaisuudesta. Kyseessä on kuitenkin Rails scaffoldingin
luoma hieman ruma koodi, joten jätämme sen paikalleen.
>
>Linkitä myös laatumetriikkaraportti repositorion README-tiedostoon:
>
>```ruby
>[![Code Climate](https://codeclimate.com/github/mluukkai/ratebeer-public.png)](https://codeclimate.com/github/mluukkai/ratebeer-public)
>```
>
> Nyt myös codeclimate aiheuttaa sovelluskehittäjälle sopivasti painetta pitää koodi koko ajan hyvälaatuisena!
>
> Huomaa, että linkin loppuosa on sama kun projektisi Github-repositorion, edellinen siis liittyy Github-repoon https://github.com/mluukkai/ratebeer-public

Codeclimaten tekemän staattisen analyysin lisäksi Rails-sovelluskehityksessä kannaa noudattaa yhtenäistä koodaustyyliä. Rails-yhteisön kehittelemä tyyliopas löytyy osoitteesta  https://github.com/bbatsov/rails-style-guide

Sovelluskehittäjän elämää helpottavien pilvipalveluiden määrä kasvaa kovaa vauhtia. Simplecov:in sijaan tai lisäksi testauskattavuuden raportoinnin voi delegoida Coveralls https://coveralls.io/ -nimiselle pilvipalvelulle.

## Kirjautuneiden toiminnot

Jätetään testien teko hetkeksi ja palataan muutamaan aiempaan teemaan. Viikolla 2 rajoitimme http basic -autentikaation avulla sovellustamme siten, että ainoastaan admin-salasanan syöttämällä oli mahdollista  poistaa panimoita. [Viikolla](3 https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko3.md#vain-omien-reittausten-poisto) rajoitimme sovelluksen toiminnallisuutta siten, että reittausten poistaminen ei ole mahdollista kuin reittauksen tehneelle käyttäjälle. Sen sijaan esim.  olutkerhojen ja oluiden luominen, poistaminen ja editionti on tällä hetkellä mahdollista jopa ilman kirjautumista.

Luovutaan http basic -autentikoinnin käytöstä ja muutetaan sovellusta siten, että oluita, panimoita ja olutkerhoja voivat luoda, muokata ja poistaa ainoastaan kirjautuneet käyttäjät.

Aloitetaan poistamalla http basic -autentikaatio. Eli poistetaan panimokontrollerista rivi

    before_action :authenticate, only: [:destroy]

sekä metodi <code>authenticate</code>. Nyt kuka tahansa voi jälleen poistaa panimoita.

Aloitetaan suojauksen lisääminen.

Näkymistä on helppo poistaa oluiden, olutkerhojen ja panimoiden muokkaus -ja luontilinkit  siinä tapauksessa, jos käyttäjä ei ole kirjautunut järjestelmään.

Esim. näkymästä views/beers/index.html.erb voidaan nyt poistaa kirjautumattomilta käyttäjiltä sivun lopussa oleva oluiden luomislinkki:

```erb
<% if not current_user.nil? %>
  <%= link_to('New Beer', new_beer_path) %>
<% end %>
```

Eli linkkielementti näytetään ainoastaan jos <code>current_user</code> ole <code>nil</code>. Voimme myös hyödyntää if:in kompaktimpaa muotoa:

```erb
<%= link_to('New Beer', new_beer_path) if not current_user.nil? %>
```

Nyt siis <code>link_to</code> metodi suoritetaan (eli linkin koodi renderöityy) ainoastaan jos if:in ehto on tosi. if not -muotoiset ehtolauseet eivät ole kovin hyvää Rubyä, parempi olisikin käyttää <code>unless</code>-ehtolausetta:

```erb
<%= link_to('New Beer', new_beer_path) unless current_user.nil? %>
```

Eli renderöidään linkki __ellei__ <code>current_user</code> ei ole <code>nil</code>.

Oikeastaan <code>unless</code> on nyt tarpeeton, rubyssä nimittäin <code>nil</code> tulkitaan epätodeksi, eli kaikkien siistein muoto komennosta on

```erb
<%= link_to('New Beer', new_beer_path) if current_user %>
```

Poistamme lisäys-, poisto- ja editointilinkit pian, ensin kuitenkin tarkastellaan kontrolleritason suojausta, nimittäin vaikka kaikki linkit rajoitettuihin toimenpiteisiin poistettaisiin, ei mikään estä tekemästä suoraa HTTP-pyyntöä sovellukselle ja tekemästä näin kirjautumattomilta rajoitettua toimenpidettä.

On siis vielä tehtävä kontrolleritasolle varmistus, että jos kirjautumaton käyttäjä jostain syystä yrittää tehdä suoraan HTTP:llä kiellettyä toimenpidettä, ei toimenpidettä suoriteta.

Päätetään ohjata rajoitettua toimenpidettä yrittävä kirjautumaton käyttäjä kirjautumissivulle.

Määritellään luokkaan <code>ApplicationController</code>  seuraava metodi:

```ruby
  def ensure_that_signed_in
    redirect_to signin_path, notice:'you should be signed in' if current_user.nil?
  end
```

Eli jos metodia kutsuttaessa käyttäjä ei ole kirjautunut, suoritetaan uudelleenohjaus kirjautumissivulle. Koska metodi on sijoitettu luokkaan <code>ApplicationController</code> jonka kaikki kontrollerit perivät, on se kaikkien kontrollereiden käytössä.

Lisätään metodi esifiltteriksi (ks. http://guides.rubyonrails.org/action_controller_overview.html#filters ja https://github.com/mluukkai/WebPalvelinohjelmointi2016/wiki/viikko-2#yksinkertainen-suojaus) olut- ja panimo- ja olutkerhokontrollerille kaikille metodeille paitsi index:ille ja show:lle:

```ruby
class BeersController < ApplicationController
  before_action :ensure_that_signed_in, except: [:index, :show]

  #...
end
```

Esim. uutta olutta luotaessa, ennen metodin <code>create</code> suorittamista, Rails suorittaa esifiltterin <code>ensure_that_signed_in</code>, joka ohjaa kirjautumattoman käyttäjän kirjautumissivulle. Jos käyttäjä on kirjautunut järjestelmään, ei filtterimetodi tee mitään, ja uusi olut luodaan normaaliin tapaan.

Kokeile selaimella, että muutokset toimivat, eli että kirjautumaton käyttäjä ohjautuu kirjautumissivulle kaikilla esifiltterillä rajoitetuilla toiminnoilla mutta että kirjautuneet pääsevät sivuille ilman ongelmaa.

> ## Tehtävä 14
>
> Estä esifiltterien avulla kirjautumattomilta käyttäjiltä panimoiden ja olutseurojen suhteen muut toiminnot paitsi kaikkien listaus ja yksittäisen resurssin tietojen tarkastelu (eli metodit <code>show</code> ja <code>index</code>)
>
> Kun olet varmistanut että toiminnallisuus on kunnossa, voit halutessasi poistaa näkymistä ylimääräiset luomis-, poisto- ja editointilinkit kirjautumattomilta käyttäjiltä

> ## Tehtävä 15
>
> Tehtävää 14 ennen tekemiemme laajennustan takia muutama ohjelman testeistä menee rikki. Korjaa testit

## Sovelluksen ulkoasun hienosäätö

Voit halutessasi tehdä hienosäätöä sovelluksen näkymiin, esim. poistaa resurssien poisto- ja editointilinkit listaussivulta:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w4-2.png)

ja lisätä poistolinkki yksittäisen resurssin sivulle:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w4-3.png)

nämä muutokset eivät ole välttämättömiä ja tulevat viikotkaan eivät muutoksiin nojaa.

## Tehtävien palautus

Commitoi kaikki tekemäsi muutokset ja pushaa koodi Githubiin. Deployaa myös uusin versio Herokuun.

Tehtävät kirjataan palautetuksi osoitteeseen http://wadrorstats2016.herokuapp.com/
