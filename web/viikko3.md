Jatkamme sovelluksen rakentamista siitä, mihin jäimme viikon 2 lopussa. Allaoleva materiaali olettaa, että olet tehnyt kaikki edellisen viikon tehtävät. Jos et tehnyt kaikkia tehtäviä, voit ottaa kurssin repositorioista [edellisen viikon mallivastauksen](https://github.com/mluukkai/WebPalvelinohjelmointi2016/tree/master/malliv/viikko2). Jos sait suurimman osan edellisen viikon tehtävistä tehtyä, saattaa olla helpointa, että täydennät vastaustasi mallivastauksen avulla.

Jos otat edellisen viikon mallivastauksen tämän viikon pohjaksi, kopioi hakemisto pois kurssirepositorion alta (olettaen että olet kloonannut sen) ja tee sovelluksen sisältämästä hakemistosta uusi repositorio.

**Huom:** muutamilla Macin käyttäjillä oli ongelmia Herokun tarvitseman pg-gemin kanssa. Paikallisesti gemiä ei tarvita ja se määriteltiinkin asennettavaksi ainoastaan tuotantoympäristöön. Jos ongelmia ilmenee, voit asentaa gemit antamalla <code>bundle install</code>-komentoon seuraavan lisämääreen:

    bundle install --without production

Tämä asetus muistetaan jatkossa, joten pelkkä `bundle install` riittää kun haluat asentaa uusia riippuvuuksia.

## Rails-ohjelmoijan workflow

Railsia tehtäessä optimaalinen työskentelytapa poikkeaa merkittävästi esim. Java-ohjelmoinnista. Railsia _ei_ yleensä kannata ohjelmoida siten, että editoriin yritetään kirjoittaa paljon valmista koodia, jonka toimivuus sitten testataan menemällä koodin suorittavalle sivulle. Osittain syy tähän on kielen dynaaminen tyypitys ja tulkattavuus, joka tekee parhaillekin IDE:ille ohjelman syntaksin tarkastuksen mahdottomaksi. Toisaalta kielen tulkattavuus ja konsolityökalut (konsoli ja debuggeri) mahdollistavat pienempien koodinpätkien toiminnallisuuden testaamisen ennen niiden siirtämistä editoitavaan kooditiedostoon.

Tarkastellaan esimerkkinä viime viikolla toteutetun oluiden reittausten keskiarvon toteuttamista luontevaa Rails-workflowta noudattaen.

Jokainen olut siis sisältää kokoelman reittauksia:

```ruby
class Beer < ActiveRecord::Base
  belongs_to :brewery
  has_many :ratings

end
```

Tehtävänämme on luoda oluelle metodi <code>average</code>

```ruby
class Beer < ActiveRecord::Base
  belongs_to :brewery
  has_many :ratings, dependent: :destroy

  def average
    # code here
  end
end
```

Voisimme toteuttaa keskiarvon laskemisen "javamaisesti" laskemalla summan käymällä reittauksen läpi alkio alkiolta ja jakamalla summan alkioden määrällä.

Kaikki rubyn kokoelmamaiset asiat (mm. taulukko ja <code>has_many</code>-kenttä) sisältävät Enumerable-moduulin (ks. http://ruby-doc.org/core-2.1.0/Enumerable.html) tarjoamat apumetodit. Päätetäänkin hyödyntää apumetodeja keskiarvon laskemisessa.

Koodin kirjoittamisessa kannattaa _ehdottomasti_ hyödyntää konsolia. Oikeastaan konsoliakin parempi vaihtoehdo on debuggerin käyttö. Debuggerin avulla saadaan avattua konsoli suoraan siihen kontekstiin, johon koodia ollaan kirjoittamassa. Lisätään metodikutsuun debuggerin käynnistävä komento <code>byebug</code>:

```ruby
class Beer < ActiveRecord::Base
  belongs_to :brewery
  has_many :ratings, dependent: :destroy

  def average
    byebug
  end
end
```

Avataan sitten konsoli, luetaan tietokannasta reittauksia sisältävä olio ja kutsutaan sille metodia <code>average</code>:

```ruby
$ rails c
Loading development environment (Rails 4.1.5)
2.2.1 :001 > b = Beer.first
  Beer Load (0.2ms)  SELECT  "beers".* FROM "beers"   ORDER BY "beers"."id" ASC LIMIT 1
 => #<Beer id: 1, name: "Iso 3", style: "Lager", brewery_id: 1, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">
2.2.1 :002 > b.average

[4, 13] in /Users/mluukkai/kurssirepot/ratebeer/app/models/beer.rb
    4:   belongs_to :brewery
    5:   has_many :ratings, dependent: :destroy
    6:
    7:   def average
    8:     byebug
=>  9:   end
   10:
   11: end
(byebug)
```

eli saamme auki debuggerisession, joka avautuu metodin sisälle. Pääsemme siis käsiksi kaikkiin oluen tietoihin.

Olioon itseensä päästään käsiksi viitteellä <code>self</code>

```ruby
(byebug) self
#<Beer id: 1, name: "Iso 3", style: "Lager", brewery_id: 1, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">
(byebug)
```

ja olioiden kenttiin pistenotaatiolla tai pelkällä kentän nimellä:

```ruby
(byebug) self.name
"Iso 3"
(byebug) style
"Lager"
(byebug)
```

Huomaa, että jos metodin sisällä on tarkotus muuttaa olion kentän arvoa, on käytettävä pistenotaatiota:

```ruby
  def metodi
    # seuraavat komennot tulostavat olion kentän name arvon
    puts self.name
    puts name

    # alustaa metodin sisälle muuttujan name ja antaa sille arvon
    name = "StrongBeer"

    # muuttaa olion kentän name arvoa
    self.name = "WeakBeer"
  end
```

Voimme siis viitata oluen reittauksiin oluen metodin sisältä kentän nimellä <code>ratings</code>:

```ruby
(byebug) ratings
  Rating Load (0.2ms)  SELECT "ratings".* FROM "ratings"  WHERE "ratings"."beer_id" = ?  [["beer_id", 1]]
#<ActiveRecord::Associations::CollectionProxy [#<Rating id: 1, score: 10, beer_id: 1, created_at: "2016-01-17 13:09:31", updated_at: "2016-01-17 13:09:31">, #<Rating id: 2, score: 21, beer_id: 1, created_at: "2016-01-17 13:09:33", updated_at: "2016-01-17 13:09:33">, #<Rating id: 3, score: 17, beer_id: 1, created_at: "2016-01-17 13:09:35", updated_at: "2016-01-17 13:09:35">, #<Rating id: 10, score: 22, beer_id: 1, created_at: "2016-01-17 15:51:02", updated_at: "2016-01-17 15:51:02">, #<Rating id: 11, score: 34, beer_id: 1, created_at: "2016-01-17 15:51:52", updated_at: "2016-01-17 15:51:52">]>
(byebug)
```

Katsotaan yksittäistä reittausta:

```ruby
(byebug) ratings.first
#<Rating id: 1, score: 10, beer_id: 1, created_at: "2016-01-17 13:09:31", updated_at: "2016-01-17 13:09:31">
(byebug)
```

summataksemme reittaukset, tulee siis jokaisesta reittausoliosta ottaa sen kentän <code>score</code> arvo:

```ruby
(byebug) ratings.first.score
10
(byebug)
```

Enumerable-modulin metodi <code>map</code> tarjoaa keinon muodostaa kokoelman perusteella uusi kokoelma, jonka alkiot saadaan alkuperäisen kokelman alkioista, suorittamalla jokaiselle alkiolle mäppäys-funktio.

Jos alkuperäisen kokoelman alkioon viitataan nimellä <code>r</code>, mäppäysfunktio on yksinkertainen:

```ruby
(byebug) r = ratings.first
(byebug) r.score
10
(byebug)
```

Nyt voimme kokeilla mitä <code>map</code> tuottaa:

```ruby
(byebug) ratings.map { |r| r.score }
[10, 21, 17, 22, 34]
(byebug)
```

mäppäysfunktio siis annetaan metodille <code>map</code> parametriksi aaltosulkein erotettuna koodilohkona. Koodilohko voitaisiin erottaa myös <code>do end</code>-parina, molemmat tuottavat saman lopputuloksen:

```ruby
(byebug) ratings.map do |r| r.score end
[10, 21, 17, 22, 34]
(byebug)
```

Metodin map avulla saamme siis muodostettua reittausten kokoelmasta taulukon reittausten arvoja. Seuraava tehtävä on summata nämä arvot.

Rails on lisännyt kaikille Enumerableille metodin
[sum](http://apidock.com/rails/Enumerable/sum), kokeillaan sitä mapilla aikansaamaamme taulukkoon.

```ruby
(byebug) ratings.map{ |r| r.score }.sum
104
(byebug)
```

Jotta saamme vielä aikaan keskiarvon, on näin saatava summa jaettava alkioiden kokonaismäärällä. Varmistetaan ensin kokonaismäärän laskevan metodin <code>count</code> tominta:

```ruby
(byebug) ratings.count
5
(byebug) ratings.map{ |r| r.score }.sum / ratings.count
```

ja muodostetaan sitten keskiarvon laskeva onelineri:

```ruby
(byebug) ratings.map{ |r| r.score }.sum / ratings.count
20
(byebug)
```

huomaamme että lopputulos pyöristyy väärin. Kyse on tietenkin siitä että sekä jaettava että jakaja ovat kokonaislukuja. Muutetaan toinen näistä liukuluvuksi. Kokeillaan ensin miten kokonaisluvusta liukuluvun tekevä metodi toimii:

```ruby
(byebug) 1.to_f
1.0
(byebug)
```

Jos et tiedä miten joku asia tehdään Rubyllä, google tietää.

Mieti sopiva hakusana niin saat melko varmasti vastauksen. Kannattaa kuitenkin olla hiukan varovainen ja tutkia ainakin muutama googlen vastaus. Ainakin kannattaa varmistaa että vastauksessa puhutaan riittävän tuoreesta rubyn tai railsin versiosta. Esim. Rails 2:ssa ja 3:ssa olevista asioista erittäin moni on muuttunut nelosversiossa.

Rybyssä ja Railsissa on useimmiten joku valmis metodi tai gemi melkein kaikkeen, eli pyörän uudelleenkeksimisen sijaan kannattaa aina googlata tai vilkuilla dokumentaatiota.

Muodostetaan sitten lopullinen versio keskiarvon laskevasta koodista:

```ruby
(byebug) ratings.map{ |r| r.score }.sum / ratings.count.to_f
20.8
(byebug)
```

Nyt koodi on valmis ja testattu, joten se voidaan kopioida metodiin:

```ruby
class Beer < ActiveRecord::Base
  belongs_to :brewery
  has_many :ratings, dependent: :destroy

  def average
    ratings.map{ |r| r.score }.sum / ratings.count.to_f
  end

end
```

Testataan metodia, eli poistutaan debuggerista (sanomalla c eli jatkamalla aiemman tyhjän metodin suoritus loppuun), _lataamalla_ uusi koodi, hakemalla olio ja suorittamalla metodi:

```ruby
(byebug) c
2.2.1 :006 > reload!
Reloading...
2.2.1 :007 > b = Beer.first
2.2.1 :008 > b.average
 => 20.8
2.2.1 :009 >
```

Jatkotestaus kuitenkin paljastaa että kaikki ei ole hyvin:

```ruby
2.2.1 :009 > b = Beer.last
 => #<Beer id: 17, name: "Hardcore IPA", style: "IPA", brewery_id: 4, created_at: "2016-01-17 17:04:50", updated_at: "2016-01-17 17:04:50">
2.2.1 :010 > b.average
 => NaN
2.2.1 :011 >
```

eli Hardcore IPA:n reittausten keskiarvo on <code>NaN</code>. Turvaudutaan jälleen debuggeriin. Laitetaan komento <code>byebug</code> keskiarvon laskevaan metodiin, uudelleenladataan koodi ja kutsutaan metodia ongelmalliselle oliolle:

```ruby
[3, 12] in /Users/mluukkai/kurssirepot/ratebeer/app/models/beer.rb
    3:
    4:   belongs_to :brewery
    5:   has_many :ratings, dependent: :destroy
    6:
    7:   def average
    8:     byebug
=>  9:     ratings.map{ |r| r.score }.sum / ratings.count.to_f
   10:   end
   11:
   12: end
(byebug)
```

Evaluoidaan lausekkeen osat debuggerissa:

```ruby
(byebug) ratings.map{ |r| r.score }.sum
0
(byebug) ratings.count.to_f
0.0
(byebug)
```

Olemme siis jakamassa kokonaisluku nollaa luvulla nolla, katsotaan mikä laskuoperaation tulos on:

```ruby
(byebug) 0/0.0
NaN
(byebug)
```

eli estääksemme nollalla jakamisen, tulee metodin käsitellä tapaus erikseen:

```ruby
  def average
    return 0 if ratings.empty?
    ratings.map{ |r| r.score }.sum / ratings.count.to_f
  end
```

Käytämme onliner-if:iä ja kokoelman metodia <code>empty?</code> joka evaluoituu todeksi kokoelman ollessa tyhjä. Kyseessä on rubymainen tapa toteuttaa tyhjyystarkastus, joka "javamaisesti" kirjotettuna olisi:

```ruby
  def average
    if ratings.count == 0
      return 0
    end
    ratings.map{ |r| r.score }.sum / ratings.count.to_f
  end
```

Kutakin kieltä käytettäessä tulee kuitenkin mukautua kielen omaan tyyliin, varsinkin jos on mukana projekteissa joita ohjelmoi useampi ihminen.

Jos et ole jo rutinoitunut debuggerin käyttöön, muista kerrata viime viikon [debuggeria käsittelevä maeriaali].
(https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#lis%C3%A4%C3%A4-rails-sovelluksen-debuggaamisesta)

## Käyttäjä ja sessio

Laajennetaan sovellusta seuraavaksi siten, että käyttäjien on mahdollista rekisteröidä itselleen järjestelmään käyttäjätunnus.
Tulemme hetken päästä muuttamaan toiminnallisuutta myös siten, että jokainen reittaus liittyy sovellukseen kirjautuneena olevaan käyttäjään:

![mvc-kuva](http://yuml.me/ddc9b7c9)

Tehdään käyttäjä ensin pelkän käyttäjätunnuksen omaavaksi olioksi ja lisätään myöhemmin käyttäjälle myös salasana.

Luodaan käyttäjää varten model, näkymä ja kontrolleri komennolla <code>rails g scaffold user username:string</code>

Uuden käyttäjän luominen tapahtuu Rails-konvention mukaan osoitteessa <code>users/new</code> olevalla lomakkeella. Olisi kuitenkin luontevampaa jos osoite olisi <code>signup</code>. Lisätään routes.rb:hen vaihtoehtoinen reitti

    get 'signup', to: 'users#new'

eli myös osoitteeseen signup tuleva HTTP GET -pyyntö käsitellään Users-kontrollerin metodin <code>new</code> avulla.

HTTP on tilaton protokolla, eli kaikki HTTP-protokollalla suoritetut pyynnöt ovat toisistaan riippumattomia. Jos Web-sovellukseen kuitenkin halutaan toteuttaa tila, esim. tieto kirjautuneesta käyttäjästä, tulee jonkinlainen tieto websession "tilasta" välittää jollain tavalla jokaisen selaimen tekemän HTTP-kutsun mukana. Yleisin tapa tilatiedon välittämiseen ovat evästeet, ks. http://en.wikipedia.org/wiki/HTTP_cookie

Lyhyesti sanottuna evästeiden toimintaperiaate on seuraava: kun selaimella mennään jollekin sivustolle, voi palvelin lähettää vastauksessa selaimelle pyynnön evästeen tallettamisesta. Jatkossa selain liittää evästeen kaikkiin sivustolle kohdistuneisiin HTTP-pyyntöihin. Eväste on käytännössä pieni määrä dataa, ja palvelin voi käyttää evästeessä olevaa dataa haluamallaan tavalla evästeen omaavan selaimen tunnistamiseen.

Railsissa sovelluskehittäjän ei ole tarvetta työskennellä suoraan evästeiden kanssa, sillä Railsiin on toteutettu evästeiden avulla hieman korkeammalla abstraktiotasolla toimivat __sessiot__ ks.
http://guides.rubyonrails.org/action_controller_overview.html#session joiden avulla sovellus voi "muistaa" tiettyyn selaimeen liittyviä asioita, esim. käyttäjän identiteetin, useiden HTTP-pyyntöjen ajan.

Kokeillaan ensin sessioiden käyttöä muistamaan käyttäjän viimeksi tekemä reittaus. Rails-sovelluksen koodissa HTTP-pyynnön tehneen käyttäjän (tai tarkemmin ottaen selaimen) sessioon pääsee käsiksi hashin kaltaisesti toimivan olion <code>session</code> kautta.

Talletetaan reittaus sessioon tekemällä seuraava lisäys reittauskontrolleriin:

```ruby
  def create
    rating = Rating.create params.require(:rating).permit(:score, :beer_id)

    # talletetaan tehdyn reittauksen sessioon
    session[:last_rating] = "#{rating.beer.name} #{rating.score} points"

    redirect_to ratings_path
  end
```

jotta  edellinen reittaus saadaan näkyviin kaikille sivuille, lisätään application layoutiin (eli tiedostoon app/views/layouts/application.html.erb) seuraava:

```erb
<% if session[:last_rating].nil? %>
  <p>no ratings given</p>
<% else %>
  <p>previous rating: <%= session[:last_rating] %></p>
<% end %>
```

Kokeillaan nyt sovellusta. Aluksi sessioon ei ole talletettu mitään ja <code>session[:last_rating]</code> on arvoltaan <code>nil</code> eli sivulla pitäisi lukea "no ratings given". Tehdään reittaus ja näemme että se tallentuu sessioon. Tehdään vielä uusi reittaus ja havaitsemme että se ylikirjoittaa sessiossa olevan tiedon.

Avaa nyt sovellus incognito-ikkunaan tai toisella selaimella. Huomaat, että toisessa selaimessa session arvo on <code>nil</code>. Eli sessio on selainkohtainen.

## Kirjautuminen

Ideana on toteuttaa kirjautuminen siten, että kirjautumisen yhteydessä talletetaan sessioon kirjautuvaa käyttäjää vastaavan <code>User</code>-olion </code>id</code>. Uloskirjautuessa sessio nollataan.

Huom: sessioon voi periaatteessa tallennella melkein mitä tahansa olioita, esim. kirjautunutta käyttäjää vastaava <code>User</code>-olio voitaisiin myös tallettaa sessioon. Hyvänä käytänteenä (ks. http://guides.rubyonrails.org/security.html#session-guidelines) on kuitenkin tallettaa sessioon mahdollisimman vähän tietoa (oletusarvoisesti Railsin sessioihin voidaan tallentaa korkeintaan 4kB tietoa), esim. juuri sen verran, että voidaan identifioida kirjautunut käyttäjä, johon liittyvät muut tiedot saadaan tarvittaessa haettua tietokannasta.

Tehdään nyt sovellukseen kirjautumisesta ja uloskirjautumisesta huolehtiva kontrolleri. Usein Railsissa on tapana noudattaa myös kirjautumisen toteuttamisessa RESTful-ideaa ja konvention mukaisia polkunimiä.

Voidaan ajatella, että kirjautumisen yhteydessä syntyy sessio, ja tätä voidaan pitää jossain mielessä samanlaisena "resurssina" kuin esim. olutta. Nimetäänkin kirjautumisesta huolehtiva kontrolleri <code>SessionsController</code>iksi

Sessio-resurssi kuitenkin poikkeaa esim. oluista siinä mielessä että tietyllä ajanhetkellä käyttäjä joko ei ole tai on kirjaantuneena. Sessioita ei siis ole yhden käyttäjän näkökulmasta oluiden tapaan useitavaan maksimissaan yksi. Kaikkien sessioiden listaa ei nyt reittien tasolla ole mielekästä olla ollenkaan olemassa kuten esim. oluiden tilanteessa on. Reitit kannattaakin kirjoittaa yksikössä ja tämä saadaan aikaan kun session retit luodaan routes.rb:hen komennolla <code>resource</code>:

    resource :session, only: [:new, :create, :destroy]

**HUOM: varmista että kirjoitat määrittelyn routes.rb:hen juuri ylläkuvatulla tavalla, eli <code>resource</code>, ei _resources_ niinkuin muiden polkujen määrittelyt on tehty.**

Kirjautumissivun osoite on nyt **session/new**. Osoitteeseen **session** tehty POST-kutsu suorittaa kirjautumisen, eli luo käyttäjälle session. Uloskirjautuminen tapahtuu tuhoamalla käyttäjän sessio eli tekemällä POST-delete kutsu osoitteeseen **session**.

Tehdään sessioista huolehtiva kontrolleri (tiedostoon app/controllers/sessions_controller.rb):

```ruby
class SessionsController < ApplicationController
  def new
    # renderöi kirjautumissivun
  end

  def create
    # haetaan usernamea vastaava käyttäjä tietokannasta
    user = User.find_by username: params[:username]
    # talletetaan sessioon kirjautuneen käyttäjän id (jos käyttäjä on olemassa)
    session[:user_id] = user.id if not user.nil?
    # uudelleen ohjataan käyttäjä omalle sivulleen
    redirect_to user
  end

  def destroy
    # nollataan sessio
    session[:user_id] = nil
    # uudelleenohjataan sovellus pääsivulle
    redirect_to :root
  end
end
```

Huomaa, että vaikka sessioiden reitit kirjoitetaan nyt yksikössä **session** ja **session/new** on kontrollerin ja näkymien hakemiston kirjoitusasu kuitenkin railsin normaalia monikkomuotoa noudattava.

Kirjautumissivun app/views/sessions/new.html.erb koodi on seuraavassa:

```erb
<h1>Sign in</h1>

<%= form_tag session_path do %>
  <%= text_field_tag :username, params[:username] %>
  <%= submit_tag "Log in" %>
<% end %>
```

Toisin kuin reittauksille tekemämme formi (kertaa asia [viime viikolta](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#lomake-ja-post)), nyt tekemämme lomake ei perustu olioon ja lomake luodaan <code>form_tag</code>-metodilla, ks. http://guides.rubyonrails.org/form_helpers.html#dealing-with-basic-forms

Lomakkeen lähettäminen siis aiheuttaa HTTP POST -pyynnön session_pathiin (huomaa yksikkömuoto!) eli osoitteeseen **session**.

Pyynnön käsittelevä metodi ottaa <code>params</code>-olioon talletetun käyttäjätunnuksen ja hakee sitä vastaavan käyttäjäolion kannasta ja tallettaa olion id:n sessioon jos olio on olemassa. Lopuksi käyttäjä uudelleenohjataan omalle sivulleen. Kontrollerin koodi vielä uudelleen seuraavassa:

```ruby
  def create
    user = User.find_by username: params[:username]
    session[:user_id] = user.id if not user.nil?
    redirect_to user
  end
```

Huom1: komento <code>redirect_to user</code> siis on lyhennysmerkintä seuraavalla <code>redirect_to user_path(user)</code>, ks. [viikko 1](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko1.md#kertausta-polkujen-ja-kontrollerien-niment%C3%A4konventiot).

Huom2: Rubyssa yhdistelmän <code>if not</code> sijaan voidaan käyttää myös komentoa <code>unless</code>, eli metodin toinen rivi oltaisiin voitu kirjoittaa muodossa

```ruby
  session[:user_id] = user.id unless user.nil?
```

Lisätään application layoutiin seuraava koodi, joka lisää kirjautuneen käyttäjän nimen kaikille sivuille (edellisessä luvussa lisätyt sessioharjoittelukoodit voi samalla poistaa):

```erb
<% if not session[:user_id].nil? %>
  <p><%= User.find(session[:user_id]).username %> signed in</p>
<% end %>
```

menemällä osoitteeseen [http://localhost:3000/session/new](/session/new) voimme nyt kirjautua sovellukseen (olettaen, että sovellukseen on luotu käyttäjiä). Uloskirjautuminen ei vielä toistaiseksi onnistu.

**HUOM:** jos saat virheilmoituksen <code>uninitialized constant SessionController></code> **varmista että määrittelit reitit routes.rb:hen oikein, eli**

```ruby
  resource :session, only: [:new, :create, :delete]
```

> ## Tehtävä 1
>
> Tee kaikki ylläesitetyt muutokset ja varmista, että kirjautuminen onnistuu (eli kirjautunut käyttäjä näytetään sivulla) olemassaolevalla käyttäjätunnuksella (jonka siis voit luoda osoitteessa [http://localhost:3000/signup](/signup). Vaikka uloskirjautuminen ei ole mahdollista, voit kirjautua uudella tunnuksella kirjautumisosoitteessa ja vanha kirjautuminen ylikirjoittuu.

## Kontrollerien ja näkymien apumetodi

Tietokantakyselyn tekeminen näkymän koodissa (kuten juuri teimme application layoutiin lisätyssä koodissa) on todella ruma tapa. Lisätään luokkaan <code>ApplicationController</code> seuraava metodi:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery

  # määritellään, että metodi current_user tulee käyttöön myös näkymissä
  helper_method :current_user

  def current_user
    return nil if session[:user_id].nil?
    User.find(session[:user_id])
  end
end
```

Koska kaikki sovelluksen kontrollerit perivät luokan <code>ApplicationController</code>, on määrittelemämme metodi kaikkien kontrollereiden käytössä. Määrittelimme lisäksi metodin <code>current_user</code> ns. helper-metodiksi, joten se tulee kontrollerien lisäksi myös kaikkien näkymien käyttöön. Voimme nyt muuttaa application layoutiin lisätyn koodin seuraavaan muotoon:

```erb
<% if not current_user.nil? %>
  <p><%= current_user.username %> signed in</p>
<% end %>
```

Voimme muotoilla ehdon myös tyylikkäämmin:

```erb
<% if current_user %>
  <p><%= current_user.username %> signed in</p>
<% end %>
```

Pelkkä <code>current_user</code> toimii ehtona, sillä arvo <code>nil</code> tulkitaan Rubyssä epätodeksi.

Kirjautumisen osoite __sessions/new__ on hieman ikävä. Määritelläänkin kirjautumista varten luontevampi vaihtoehtoinen osoite __signin__. Määritellään myös reitti uloskirjautumiselle. Lisätään siis seuraavat routes.rb:hen:

```ruby
  get 'signin', to: 'sessions#new'
  delete 'signout', to: 'sessions#destroy'
```

eli sisäänkirjautumislomake on nyt osoitteessa [http://localhost:3000/signin][/signin] ja uloskirjautuminen tapahtuu osoitteeseen _signout_ tehtävän _HTTP DELETE_ -pyynnön avulla.

Olisi periaatteessa ollut mahdollista määritellä myös

```ruby
  get 'signout', to: 'sessions#destroy'
```

eli mahdollistaa uloskirjautuminen HTTP GET:in avulla. Ei kuitenkaan pidetä hyvänä käytänteenä, että HTTP GET -pyyntö tekee muutoksia sovelluksen tilaan ja pysyttäydytään edelleen REST-filosofian mukaisessa käytänteessä, jonka mukaan resurssin tuhoaminen tapahtuu HTTP DELETE -pyynnöllä. Tässä tapauksessa vaan resurssi on hieman laveammin tulkittava asia eli käyttäjän sisäänkirjautuminen.

> ## Tehtävä 2
>
> Muokkaa nyt sovelluksen application layoutissa olevaa navigaatiopalkkia siten, että palkkiin tulee näkyville sisään- ja uloskirjautumislinkit. Huomioi, että uloskirjautumislinkin yhteydessä on määriteltävä käytettäväksi HTTP-metodiksi DELETE, katso esimerkki tähän esim. kaikki käyttäjät listaavalta sivulta.
>
> Edellisten lisäksi lisää palkkiin linkki kaikkien käyttäjien sivulle, sekä kirjautuneen käyttäjän nimi, joka toimii linkkinä käyttäjän omalle sivulle. Käyttäjän ollessa kirjaantuneena tulee palkissa olla myös linkki uuden oluen reittaukseen.
>
> Muistutus: näen järjestelmään määritellyt routet ja polkuapumetodit komentoriviltä komennolla <code>rake routes</code> tai menemällä mihin tahansa sovelluksen osoitteeseen, jota ei ole olemassa, esim. [http://localhost:3000/wrong](http://localhost:3000/wrong)

Tehtävän jälkeen sovelluksesi näyttää suunnilleen seuraavalta jos käyttäjä on kirjautuneena:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-1.png)


ja seuraavalta jos käyttäjä ei ole kirjautuneena (huomaa, että nyt näkyvillä on myös uuden käyttäjän rekisteröitymiseen tarkoitettu signup-linkki):

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-2.png)

## Reittaukset käyttäjälle

Muutetaan seuraavaksi sovellusta siten, että reittaus kuuluu kirjautuneena olevalle käyttäjälle, eli tämän vaiheen jälkeen olioiden suhteen tulisi näyttää seuraavalta:

![kuva](http://yuml.me/ccdb3938)

Modelien tasolla muutos kulkee tuttuja latuja:

```ruby
class User < ActiveRecord::Base
  has_many :ratings   # käyttäjällä on monta ratingia
end

class Rating < ActiveRecord::Base
  belongs_to :beer
  belongs_to :user   # rating kuuluu myös käyttäjään

  def to_s
    "#{beer.name} #{score}"
  end
end
```

Ratkaisu ei kuitenkaan tällaisenaan toimi. Yhteyden takia _ratings_-tietokantatauluun riveille tarvitaan vierasavaimeksi viite käyttäjän id:hen. Railsissa kaikki muutokset tietokantaan tehdään Ruby-koodia olevien *migraatioiden* avulla. Luodaan nyt uuden sarakkeen lisäävä migraatio. Generoidaan ensin migraatiotiedosto komentoriviltä komennolla:

    rails g migration AddUserIdToRatings

Hakemistoon _db/migrate_ ilmestyy tiedosto, jonka sisältö on seuraava

```ruby
class AddUserIdToRatings < ActiveRecord::Migration
  def change
  end
end
```

Huomaa, että hakemistossa on jo omat migraatiotiedostot kaikkia luotuja tietokantatauluja varten. Jokaiseen migraatioon sisällytetään tieto sekä tietokantaan tehtävästä muutoksesta että muutoksen mahdollisesta perumisesta. Jos migraatio on riittävän yksinkertainen, eli sellainen että Rails osaa päätellä suoritettavasta lisäyksestä myös sen peruvan operaation, riittää että migraatiossa on määriteltynä ainoastaan metodi <code>change</code>. Jos migraatio on monimutkaisempi, on määriteltävä metodit <code>up</code> ja <code>down</code> jotka määrittelevät erikseen migraation tekemisen ja sen perumisen.

Tällä kertaa tarvittava migraatio on yksinkertainen:

```ruby
class AddUserIdToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :user_id, :integer
  end
end
```

Jotta migraation määrittelemä muutos tapahtuu, suoritetaan komentoriviltä tuttu komento <code>rake db:migrate</code>

Migraatiot ovat varsin laaja aihe ja harjoittelemme niitä vielä lisää myöhemmin kurssilla. Lisää migraatiosta löytyy osoitteesta http://guides.rubyonrails.org/migrations.html

Huomaamme nyt konsolista, että yhteys olioiden välillä toimii:

```ruby
2.2.1 :001 > u = User.first
2.2.1 :002 > u.ratings
  Rating Load (0.4ms)  SELECT "ratings".* FROM "ratings"  WHERE "ratings"."user_id" = ?  [["user_id", 1]]
 => #<ActiveRecord::Associations::CollectionProxy []>
2.2.1 :003 >
irb(main):003:0>
```

Toistaiseksi antamamme reittaukset eivät liity mihinkään käyttäjään:

```ruby
2.2.1 :003 > r = Rating.first
2.2.1 :004 > r.user
 => nil
2.2.1 :005 >
```

Päätetään että laitetaan kaikkien olemassaolevien reittausten käyttäjäksi järjestelmään ensimmäisenä luotu käyttäjä:

```ruby
2.2.1 :005 > u = User.first
2.2.1 :006 > Rating.all.each{ |r| u.ratings << r }
 => 14
2.2.1 :008 >
```

**HUOM:** reittausten tekeminen käyttöliittymän kautta ei toistaiseksi toimi kunnolla, sillä näin luotuja uusia reittauksia ei vielä liitetä mihinkään käyttäjään. Korjaamme tilanteen pian.

> ## Tehtävä 3
>
>  Lisää käyttäjän sivulle eli näkymään app/views/users/show.html.erb
> * käyttäjän reittausten määrä ja keskiarvo (huom: käytä edellisellä viikolla  määriteltyä moduulia <code>RatingAverage</code>, jotta saat keskiarvon laskevan koodin käyttäjälle!)
> * lista käyttäjän reittauksista ja mahdollisuus poistaa reittauksia

Käyttäjän sivu siis näyttää suunilleen seuraavalta (**HUOM:** sivulle olisi pitänyt lisätä myös tieto käyttäjän antamien reittausten keskiarvosta mutta se unohtui...):

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-3.png)

Reittauksen poisto vie nyt kaikkien reittausten sivulle. Luontevinta olisi, että poiston jälkeen palattaisiin takaisin käyttäjän sivulle. Tee seuraava muutos reittauskontrolleriin, jotta näin tapahtuisi:

```ruby
  def destroy
    rating = Rating.find(params[:id])
    rating.delete
    redirect_to :back
  end
```

Eli kuten arvata saattaa, <code>redirect_to :back</code> aiheuttaa uudelleenohjauksen takaisin siihen osoitteeseen, jolta HTTP DELETE -pyynnön aiheuttama linkin klikkaus suoritettiin.

Uusien reittausten luominen www-sivulta ei siis tällä hetkellä toimi, koska reittaukseen ei tällä hetkellä liitetä kirjautuneena olevaa käyttäjää. Muokataan siis  reittauskontrolleria siten, että kirjautuneena oleva käyttäjä linkitetään luotavaan reittaukseen:

```ruby
  def create
    rating = Rating.create params.require(:rating).permit(:score, :beer_id)
    current_user.ratings << rating
    redirect_to current_user
  end
```

Huomaa, että <code>current_user</code> on luokkaan <code>ApplicationController</code> äsken lisäämämme metodi, joka palauttaa kirjautuneena olevan käyttäjän eli suorittaa koodin:

```ruby
  User.find(session[:user_id])
```

Reittauksen luomisen jälkeen kontrolleri on laitettu uudelleenohjaamaan selain kirjautuneena olevan käyttäjän sivulle.

> ## Tehtävä 4
>
> Muuta sovellusta vielä siten, että kaikkien reittausten sivulla ei ole enää mahdollisuutta reittausten poistoon ja että reittauksen yhteydessä näkyy reittauksen tekijän nimi, joka myös toimii linkkinä reittaajan sivulle.

Kaikkien reittausten sivun tulisi siis näyttää edellisen tehtävän jälkeen seuraavalta:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-4.png)

## Kirjautumisen hienosäätöä

Tällä hetkellä sovellus käyttäytyy ikävästi, jos kirjautumista yritetään olemassaolemattomalla käyttäjänimellä.

Muutetaan sovellusta siten, että uudelleenohjataan käyttäjä takaisin kirjautumissivulle, jos kirjautuminen epäonnistuu. Eli muutetaan sessiokontrolleria seuraavasti:

```ruby
    def create
      user = User.find_by username: params[:username]
      if user.nil?
        redirect_to :back
      else
        session[:user_id] = user.id
        redirect_to user
      end
    end
```

muutetaan edellistä vielä siten, että lisätään käyttäjälle kirjautumisen epäonnistuessa, sekä onnistuessa näytettävät viestit:

```ruby
    def create
      user = User.find_by username: params[:username]
      if user.nil?
        redirect_to :back, notice: "User #{params[:username]} does not exist!"
      else
        session[:user_id] = user.id
        redirect_to user, notice: "Welcome back!"
      end
    end
```

Jotta viesti saadaan näkyville kirjautumissivulle, lisätään näkymään ```app/views/sessions/new.html.erb``` seuraava elementti:

```erb
<p id="notice"><%= notice %></p>
```

Elementti on jo valmiina käyttäjän sivun templatessa (ellet vahingossa poistanut sitä), joten viesti toimii siellä.

Sivulla tarvittaessa näytettävät, seuraavaan HTTP-pyyntöön muistettavat eli uudelleenohjauksenkin yhteydessä toimivat viestit eli __flashit__ on toteutettu Railssissa sessioiden avulla, ks. lisää http://guides.rubyonrails.org/action_controller_overview.html#the-flash

## Olioiden kenttien validointi

Sovelluksessamme on tällä hetkellä pieni ongelma: on mahdollista luoda useita käyttäjiä, joilla on sama käyttäjätunnus. User-kontrollerin metodissa <code>create</code> pitäisi siis tarkastaa, ettei <code>username</code> ole jo käytössä.

Railsiin on sisäänrakennettu monipuolinen mekanismi olioiden kenttien validointiin, ks http://guides.rubyonrails.org/active_record_validations.html ja http://apidock.com/rails/ActiveModel/Validations/ClassMethods

Käyttäjätunnuksen yksikäsitteisyyden validointi onkin helppoa, pieni lisäys User-luokkaan riittää:

```ruby
class User < ActiveRecord::Base
  include RatingAverage

  validates :username, uniqueness: true

  has_many :ratings
end
```

Jos nyt yritetään luoda uudelleen jo olemassaoleva käyttäjä, huomataan että Rails osaa generoida sopivan virheilmoituksen automaattisesti.

Rails (tarkemmin sanoen ActiveRecord) suorittaa oliolle määritellyt validoinnit juuri ennen kuin olio yritetään tallettaa tietokantaan esim. operaatioiden <code>create</code> tai <code>save</code> yhteydessä. Jos validointi epäonnistuu, olioa ei tallenneta.

Lisätään saman tien muitakin validointeja sovellukseemme. Lisätään käyttäjälle vaatimus, että käyttäjätunnuksen pituuden on oltava vähintään 3 merkkiä, eli lisätään User-luokkaan rivi:

```ruby
  validates :username, length: { minimum: 3 }
```

samaa attribuuttia koskevat validointisäännöt voidaan myös yhdistää, yhden <code>validates :attribuutti</code> -kutsun alle:

```ruby
class User < ActiveRecord::Base
  include RatingAverage

  validates :username, uniqueness: true,
                       length: { minimum: 3 }

  has_many :ratings
end
```

Railsin scaffold-generaattorilla luodut kontrollerit toimivat siis siten, että jos validointi onnistuu ja olio on tallentunut kantaan, uudelleenohjataan selain luodun olion sivulle. Jos taas validointi epäonnistuu, näytetään uudelleen olion luomisesta huolehtiva lomake ja renderöidään virheilmoitukset lomakkeen näyttävälle sivulle.

Mistä kontrolleri tietää, että validointi on epäonnistunut? Kuten mainittiin, validointi tapahtuu tietokantaan talletuksen yhteydessä. Jos kontrolleri tallettaa olion metodilla <code>save</code>, voi kontrolleri testata metodin paluuarvosta onko validointi onnistunut:

```ruby
  @user = User.new(parametrit)
  if @user.save
  	# validointi onnistui, uudelleenohjaa selain halutulle sivulle
  else
    # validointi epäonnistui, renderöi näkymätemplate :new
  end
```

Scaffoldin generoima kontrolleri näyttää hieman monimutkaisemmalta:


```ruby
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render action: 'show', status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

Ensinnäkin mistä tulee olion luonnissa parametrina käytettävä <code>user_params</code>? Huomaamme, että tiedoston alalaitaan on määritelty metodi

```ruby
    def user_params
      params.require(:user).permit(:username)
    end
```

eli metodin <code>create</code> ensimmäinen rivi on siis sama kuin

```ruby
   @user = User.new(params.require(:user).permit(:username))
```

Entä mitä metodin päättävä <code>respond_to</code> tekee? Jos olion luonti tapahtuu normaalin lomakkeen kautta, eli selain odottaa takaisin HTML-muotoista vastausta, on toiminnallisuus oleellisesti seuraava:

```ruby
 if @user.save
  redirect_to @user, notice: 'User was successfully created.'
 else
  render action: 'new'
 end
```

eli suoritetaan komentoon (joka on oikeastaan metodi) <code>respond_to</code> liittyvässä koodilohkossa merkintään (joka on jälleen teknisesti ottaen metodikutsu) <code>format.html</code> liittyvä koodilohko. Jos taas käyttäjä-olion luova HTTP POST -kutsu olisi tehty siten, että vastausta odotettaisiin json-muodossa (näin tapahtuisi esim. jos pyyntö tehtäisiin toisesta palvelusta tai Web-sivulta javascriptillä), suoritettaisiin <code>format.json</code>:n liittyvä koodi. Syntaksi saattaa näyttää aluksi oudolta, mutta siihen tottuu pian.

Jatketaan sitten validointien parissa. Määritellään että oluen reittauksen tulee olla kokonaisluku väliltä 1-50:

```ruby
class Rating < ActiveRecord::Base
  belongs_to :beer
  belongs_to :user

  validates :score, numericality: { greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: 50,
                                    only_integer: true }

   # ...
end
```

Jos luomme nyt virheellisen reittauksen, ei se talletu kantaan. Huomamme kuitenkin, että emme saa virheilmoitusta. Ongelmana on se, että loimme lomakkeen käsin ja se ei sisällä scaffoldingin yhteydessä automaattisesti generoituvien lomakkeiden tapaan virheraportointia ja että kontrolleri ei tarkista millään tavalla validoinnin onnistumista.

Muutetaan ensin reittaus-kontrollerin metodia <code>create</code> siten, että validoinnin epäonnistuessa se renderöi uudelleen reittauksen luomisesta huolehtivan lomakkeen:

```ruby
  def create
    @rating = Rating.new params.require(:rating).permit(:score, :beer_id)

    if @rating.save
      current_user.ratings << @rating
      redirect_to user_path current_user
    else
      @beers = Beer.all
      render :new
    end
  end
```

Metodissa luodaan siis ensin Rating-olio <code>new</code>:llä, eli sitä ei vielä talleteta tietokantaan. Tämän jälkeen suoritetaan tietokantaan tallennus metodilla <code>save</code>. Jos tallennuksen yhteydessä suoritettava olion validointi epäonnistuu, metodi palauttaa epätoden, ja olio ei tallennu kantaan. Tällöin renderöidään new-näkymätemplate. Näkymätemplaten renderöinti edellyttää, että oluiden lista on talletettu muuttujaan <code>@beers</code>.

Kun nyt yritämme luoda virheellisen reittauksen, käyttäjä pysyy lomakkeen näyttävässä näkymässä (joka siis teknisesti ottaen renderöidään uudelleen POST-kutsun jälkeen). Virheilmoituksia ei kuitenkaan vielä näy.

Validoinnin epäonnistuessa Railsin validaattori tallettaa virheilmoitukset <code>@ratings</code> olion kenttään <code>@rating.errors</code>.

Muutetaan lomaketta siten, että lomake näyttää kentän <code>@rating.errors</code> arvon, jos kenttään on asetettu jotain:

```erb
<h2>Create new rating</h2>

<%= form_for(@rating) do |f| %>
  <% if @rating.errors.any? %>
  	<%= @rating.errors.inspect %>
  <% end %>

  <%= f.select :beer_id, options_from_collection_for_select(@beers, :id, :to_s) %>
  score: <%= f.number_field :score %>
  <%= f.submit %>

<% end %>
```

Kun nyt luot virheellisen reittauksen, huomaat että virheen syy selviää kenttään <code>@rating.errors</code> talletetusta oliosta.

Otetaan sitten mallia esim. näkymätemplatesta views/users/_form.html.erb ja muokataan lomakettamme (views/ratings/new.html.erb) seuraavasti:

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

  <%= f.select :beer_id, options_from_collection_for_select(@beers, :id, :to_s) %>
  score: <%= f.number_field :score %>
  <%= f.submit %>

<% end %>
```

Validointivirheitä löytyessä, näkymätemplate renderöi nyt kaikki joukossa <code>@rating.errors.full_messages</code> olevat virheilmoitukset.

**Huom:** validoinnin epäonnistuessa ei siis suoriteta uudelleenohjausta (miksi se ei tässä tapauksessa toimi?), vaan renderöidään näkymätemplate, johon tavallisesti päädytään <code>new</code>-metodin suorituksen yhteydessä.

Apuja seuraaviin tehtäviin löytyy osoitteesta
http://guides.rubyonrails.org/active_record_validations.html ja http://apidock.com/rails/ActiveModel/Validations/ClassMethods

> ## Tehtävä 5
>
> Lisää ohjelmaasi seuraavat validoinnit
> * oluen ja panimon nimi on epätyhjä
> * panimon perustamisvuosi on kokonaisluku väliltä 1042-2016
> * käyttäjätunnuksen eli User-luokan attribuutin username pituus on vähintään 3 mutta enintään 15 merkkiä

Jos yrität luoda oluen tyhjällä nimellä, seurauksena on virheilmoitus:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-9.png)

Mistä tämä johtuu? Jos oluen luonti epäonnistuu validoinnissa tapahtuneen virheen takia, olutkontrollerin metodi <code>create</code> suorittaa else-haaran, eli renderöi uudelleen oluiden luomiseen käytettävän lomakkeen. Oluiden luomiseen käytettävä lomake käyttää muuttujaan <code>@styles</code> talletettua oluttyylien listaa lomakkeen generointiin. Virheilmoituksen syynä onkin se, että muuttujaa ei ole nyt alustettu (toisin kuin jos lomakkeeseen mennään kontrollerimetodin <code>new</code> kautta). Lomake olettaa myös, että muuttujaan <code>@breweries</code> on talletettu kaikkien panimoiden lista. Eli ongelma korjautuu jos alustamme muuttujat else-haarassa:

``` ruby
  def create
    @beer = Beer.new(beer_params)

    respond_to do |format|
      if @beer.save
        format.html { redirect_to beers_path, notice: 'Beer was successfully created.' }
        format.json { render :show, status: :created, location: @beer }
      else
        @breweries = Brewery.all
        @styles = ["Weizen", "Lager", "Pale ale", "IPA", "Porter"]
        format.html { render :new }
        format.json { render json: @beer.errors, status: :unprocessable_entity }
      end
    end
  end
```

> ## Tehtävä 6
>
> ### tehtävän teko ei ole viikon jatkamisen kannalta välttämätöntä eli ei kannata juuttua tähän tehtävään. Voit tehdä tehtävän myös viikon muiden tehtävien jälkeen.
>
> Parannellaan tehtävän 5 validointia siten, että panimon perustamisvuoden täytyy olla kokonaisluku, jonka suuruus on vähintään 1042 ja korkeintaan menossa oleva vuosi. Vuosilukua ei siis saa kovakoodata.
>
> Huomaa, että seuraava ei toimi halutulla tavalla:
>
>   validates :year, numericality: { less_than_or_equal_to: Time.now.year }
>
> Nyt käy siten, että <code>Time.now.year</code> evaluoidaan siinä vaiheessa kun ohjelma lataa luokan koodin. Jos esim. ohjelma käynnistetään vuoden 2016 lopussa, ei vuoden 2017 alussa voida rekisteröidä 2017 aloittanutta panimoa, sillä vuoden yläraja validoinnissa on ohjelman käynnistyshetkellä evaluoitunut 2016
>
> Eräs kelvollinen ratkaisutapa on oman validointimetodin määritteleminen http://guides.rubyonrails.org/active_record_validations.html#custom-methods
>
> Koodimäärällisesti lyhyempiäkin ratkaisuja löytyy, vihjeenä olkoon lambda/Proc/whatever...


## Monen suhde moneen -yhteydet

Yhteen olueeseen liittyy monta reittausta, ja reittaus liittyy aina yhteen käyttäjään, eli olueeseen liittyy monta reittauksen tehnyttä käyttäjää. Vastaavasti käyttäjällä on monta reittausta ja reittaus liittyy yhteen olueeseen. Eli käyttäjään liittyy monta reitattua olutta. Oluiden ja käyttäjien välillä on siis **monen suhde moneen -yhteys**, jossa ratings-taulu toimii liitostaulun tavoin.

Saammekin tuotua tämän many to many -yhteyden kooditasolle helposti käyttämällä jo [edellisen viikon lopulta tuttua](https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#olioiden-ep%C3%A4suora-yhteys) tapaa, eli **has_many through** -yhteyttä:

```ruby
class Beer < ActiveRecord::Base
  include RatingAverage

  belongs_to :brewery
  has_many :ratings, dependent: :destroy
  has_many :users, through: :ratings

  # ...
end

class User < ActiveRecord::Base
  include RatingAverage

  has_many :ratings
  has_many :beers, through: :ratings

  # ...
end
```

Ja monen suhde moneen -yhteys toimii käyttäjästä päin:

```ruby
2.2.1 :009 > User.first.beers
 => #<ActiveRecord::Associations::CollectionProxy [#<Beer id: 1, name: "Iso 3", style: "Lager", brewery_id: 1, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">, #<Beer id: 1, name: "Iso 3", style: "Lager", brewery_id: 1, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">, #<Beer id: 11, name: "Punk IPA", style: "IPA", brewery_id: 4, created_at: "2016-01-17 13:12:12", updated_at: "2016-01-17 13:12:12">, #<Beer id: 11, name: "Punk IPA", style: "IPA", brewery_id: 4, created_at: "2016-01-17 13:12:12", updated_at: "2016-01-17 13:12:12">, #<Beer id: 11, name: "Punk IPA", style: "IPA", brewery_id: 4, created_at: "2016-01-17 13:12:12", updated_at: "2016-01-17 13:12:12">, #<Beer id: 12, name: "Nanny State", style: "lowalcohol", brewery_id: 4, created_at: "2016-01-17 13:12:27", updated_at: "2016-01-17 13:12:52">, #<Beer id: 12, name: "Nanny State", style: "lowalcohol", brewery_id: 4, created_at: "2016-01-17 13:12:27", updated_at: "2016-01-17 13:12:52">, #<Beer id: 7, name: "Helles", style: "Lager", brewery_id: 3, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">, #<Beer id: 1, name: "Iso 3", style: "Lager", brewery_id: 1, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">, #<Beer id: 4, name: "Huvila Pale Ale", style: "Pale Ale", brewery_id: 2, created_at: "2016-01-11 14:29:25", updated_at: "2016-01-11 14:29:25">, ...]>
2.2.1 :011 >
```

ja oluesta päin:

```ruby
2.2.1 :011 > Beer.first.users
 => #<ActiveRecord::Associations::CollectionProxy [#<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 2, username: "pekka", created_at: "2016-01-24 16:51:42", updated_at: "2016-01-24 16:51:42">]>
2.2.1 :013 >
irb(main):010:0>
```

Vaikuttaa ihan toimivalta, mutta tuntuu hieman kömpeltä viitata oluen reitanneisiin käyttäjiin nimellä <code>users</code>. Luontevampi viittaustapa oluen reitanneisiin käyttäjiin olisi kenties <code>raters</code>. Tämä onnistuu vaihtamalla yhteyden määrittelyä seuraavasti

```ruby
has_many :raters, through: :ratings, source: :user
```

Oletusarvoisesti <code>has_many</code> etsii liitettävää taulun nimeä ensimmäisen parametrinsa nimen perusteella. Koska <code>raters</code> ei ole nyt yhteyden kohteen nimi, on se määritelty erikseen _source_-option avulla.

Yhteytemme uusi nimi toimii:

```ruby
2.2.1 :014 > b = Beer.first
2.2.1 :015 > b.raters
 => #<ActiveRecord::Associations::CollectionProxy [#<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 2, username: "pekka", created_at: "2016-01-24 16:51:42", updated_at: "2016-01-24 16:51:42">]>
2.2.1 :016 >
```

Koska sama käyttäjä voi tehdä useita reittauksia samasta oluesta, näkyy käyttäjä useaan kertaan oluen reittaajien joukossa. Jos haluamme yhden reittaajan näkymään ainoastaan kertaalleen, onnistuu tämä esim. seuraavasti:

```ruby
irb(main):013:0> b.raters.uniq
2.2.1 :016 > b.raters.uniq
 => [#<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 14:20:10">, #<User id: 2, username: "pekka", created_at: "2016-01-24 16:51:42", updated_at: "2016-01-24 16:51:42">]
2.2.1 :017 >
```

Olisi mahdollista myös määritellä, että oluen <code>raters</code> palauttaisi oletusarvoisesti vain kertaalleen yksittäisen käyttäjän. Tämä onnistuisi asettamalla <code>has_many</code>-määreelle __scope__, joka rajoittaa niiden olioiden joukkoa, jotka näytetään assosiaatioon liittyviksi:

```ruby
class Beer < ActiveRecord::Base
  #...

  has_many :raters, -> { uniq }, through: :ratings, source: :user

  #...
end
```

Lisää asiaa yhteyksien määrittelemisestä normaaleissa ja hieman monimutkaisemmissa tapauksissa löytyy sivulta http://guides.rubyonrails.org/association_basics.html

Huom: Railsissa on myös toinen tapa many to many -yhteyksien luomiseen <code>has_and_belongs_to_many</code> ks. http://guides.rubyonrails.org/association_basics.html#the-has-and-belongs-to-many-association jonka käyttö saattaa tulla kyseeseen jos liitostaulua ei tarvita mihinkään muuhun kuin yhteyden muodostamiseen.

Trendinä kuitenkin on, että metodin has_and_belongs_to_many sijaan käytetään (sen monien ongelmien takia)  has_many through -yhdistelmää ja eksplisiittisesti määriteltyä yhteystaulua. Mm. Chad Fowler kehottaa kirjassaan [Rails recepies](http://pragprog.com/book/rr2/rails-recipes) välttämään has_and_belongs_to_many:n käyttöä, sama neuvo annetaan Obie Fernandezin autoritiivisessa teoksessa [Rails 4 Way](https://leanpub.com/tr4w)

> ## Tehtävät 7-8: Olutseurat
>
> ### Tämän ja seuraavan tehtävän tekeminen ei ole välttämätöntä viikon jatkamisen kannalta. Voit tehdä tämän tehtävän myös viikon muiden tehtävien jälkeen.
>
> Laajennetaan järjestelmää siten, että käyttäjillä on mahdollista olla eri _olutseurojen_ jäseninä.
>
> Luo scaffoldingia hyväksikäyttäen model <code>BeerClub</code>, jolla on attribuutit <code>name</code> (merkkijono) <code>founded</code> (kokonaisluku) ja <code>city</code> (merkkijono)
>
> Muodosta <code>BeerClub</code>in ja <code>User</code>ien välille monen suhde moneen -yhteys. Luo tätä varten liitostauluksi model <code>Membership</code>, jolla on attribuutteina vierasavaimet <code>User</code>- ja <code>BeerClub</code>-olioihin (eli <code>beer_club_id</code> ja <code>user_id</code>, huomaa miten iso kirjain olion keskellä muuttuu alaviivaksi!). Tämänkin modelin voit luoda scaffoldingilla.
>
> Voit toteuttaa tässä vaiheessa jäsenien liittämisen olutseuroihin esim. samalla tavalla kuten oluiden reittaus tapahtuu tällä hetkellä, eli lisäämällä navigointipalkkiin linkin "join a club", jonka avulla kirjautunut käyttäjä voidaan littää johonkin listalla näytettävistä olutseuroista.
>
> Listaa olutseuran sivulla kaikki jäsenet ja vastaavasti henkilöiden sivulla kaikki olutseurat, joiden jäsen henkilö on. Lisää navigointipalkkiin linkki kaikkien olutseurojen listalle.
>
> Tässä vaiheessa ei ole vielä tarvetta toteuttaa toiminnallisuutta, jonka avulla käyttäjän voi poistaa olutseurasta.

> # Tehtävä 9
>
> Hio edellisessä tehävässä toteuttamaasi toiminnallisuutta siten, että käyttäjä ei voi liittyä useampaan kertaan samaan olutseuraan.

Seuraavat kaksi kuvaa antavat suuntaviivoja sille miltä sovelluksesi voi näyttää tehtävien 7-9 jälkeen.

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-5.png)

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-6.png)

## Salasana

Muutetaan sovellusta vielä siten, että käyttäjillä on myös salasana. Tietoturvasyistä salasanaa ei kannata tallentaa tietokantaan. Kantaan talletetaan ainoastaan salasanasta yhdensuuntaisella funktiolla laskettu tiiviste. Tehdään tätä varten migraatio:

    rails g migration AddPasswordDigestToUser

migraation (ks. hakemisto db/migrate) koodiksi tulee seuraava:

```ruby
class AddPasswordDigestToUser < ActiveRecord::Migration
  def change
    add_column :users, :password_digest, :string
  end
end
```

huomaa, että lisättävän sarakkeen nimen on oltava <code>password_digest</code>.

Tehdään seuraava lisäys luokkaan <code>User</code>:

```ruby
class User < ActiveRecord::Base
  include RatingAverage

  has_secure_password

  # ...
end
```

<code>has_secure_password</code> (ks. http://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html) lisää luokalle toiminnallisuuden, jonka avulla salasanan _tiiviste_ talletetaan kantaan ja käyttäjä voidaan tarpeen vaatiessa autentikoida.

Rails käyttää tiivisteen tallettamiseen <code>bcrypt-ruby</code> gemiä. Otetaan se käyttöön lisäämällä Gemfile:en rivi

    gem 'bcrypt', '~> 3.1.7'

Tämän jälkeen annetaan komentoriviltä komento <code>bundle install</code> jotta gem asentuu.

**Huom:** jos käytät hieman vanhempaa railsin versiota, joudut käyttämään eri gemiä:

    gem 'bcrypt-ruby', '~> 3.1.2'

Kokeillaan nyt hieman uutta toiminnallisuutta konsolista (joudut uudelleenkäynnistämään konsolin, jotta se saa käyttöönsä uuden gemin).

__Muista myös suorittaa migraatio!__

Salasanatoiminnallisuus <code>has_secure_password</code> lisää oliolle  attribuutit <code>password</code> ja <code>password_confirmation</code>. Ideana on, että salasana ja se varmistettuna sijoitetaan näihin attribuutteihin. Kun olio talletetaan tietokantaan esim. metodin <code>save</code> kutsun yhteydessä, lasketaan tiiviste joka tallettuu tietokantaan olion sarakkeen <code>password_digest</code> arvoksi. Selväkielinen salasana eli attribuutti <code>password</code> ei siis tallennu tietokantaan, vaan on ainoastaan olion muistissa olevassa representaatiossa.


Talletetaan käyttäjälle salasana:

```ruby
2.2.1 :004 > u = User.first
2.2.1 :005 > u.password = "salainen"
2.2.1 :006 > u.password_confirmation = "salainen"
2.2.1 :007 > u.save
   (0.2ms)  begin transaction
  User Exists (0.3ms)  SELECT  1 AS one FROM "users"  WHERE ("users"."username" = 'mluukkai' AND "users"."id" != 1) LIMIT 1
Binary data inserted for `string` type on column `password_digest`
  SQL (0.4ms)  UPDATE "users" SET "password_digest" = ?, "updated_at" = ? WHERE "users"."id" = 1  [["password_digest", "$2a$10$DZaWkl73GurTQG3ilOVz9./X6jGT49ngZb3Q9ZCF3YjVvXPrl1JLm"], ["updated_at", "2016-01-24 18:28:24.069587"]]
   (0.8ms)  commit transaction
 => true
2.2.1 :008 >
```

Jos komento <code>u.password = "salainen"</code> saa aikaan virheilmoituksen <code>NoMethodError: undefined method `password_digest=' for ...</code>, käynnistä konsoli uudelleen ja muista myös suorittaa migraatio!

Autentikointi tapahtuu <code>User</code>-olioille lisätyn metodin <code>authenticate</code> avulla seuraavasti:

```ruby
2.2.1 :008 > u.authenticate "salainen"
 => #<User id: 1, username: "mluukkai", created_at: "2016-01-24 14:20:10", updated_at: "2016-01-24 18:28:24", password_digest: "$2a$10$DZaWkl73GurTQG3ilOVz9./X6jGT49ngZb3Q9ZCF3Yj...">
2.2.1 :009 > u.authenticate "wrong"
 => false
2.2.1 :010 >
```

eli metodi <code>authenticate</code> palauttaa <code>false</code>, jos sille parametrina annettu salasana on väärä. Jos salasana on oikea, palauttaa metodi olion itsensä.

Lisätään nyt kirjautumiseen salasanan tarkistus. Muutetaan ensin kirjautumissivua (app/views/sessions/new.html.erb) siten että käyttäjätunnuksen lisäksi pyydetään salasanaa (huomaa että lomakkeen kentän tyyppi on nyt *password_field*, joka näyttää kirjoitetun salasanan sijasta ruudulla ainoastaan tähtiä):

```erb
<h1>Sign in</h1>

<p id="notice"><%= notice %></p>

<%= form_tag session_path do %>
  username <%= text_field_tag :username, params[:username] %>
  password <%= password_field_tag :password, params[:password] %>
  <%= submit_tag "Log in" %>
<% end %>
```

ja muutetaan sessions-kontrolleria siten, että se varmistaa metodia <code>authenticate</code> käyttäen, että lomakkeelta on annettu oikea salasana.

```ruby
    def create
      user = User.find_by username: params[:username]
      if user && user.authenticate(params[:password])
        session[:user_id] = user.id
        redirect_to user_path(user), notice: "Welcome back!"
      else
        redirect_to :back, notice: "Username and/or password mismatch"
      end
    end
```

Kokeillaan toimiiko kirjautuminen (**huom: jotta bcrypt-gem tulisi sovelluksen käyttöön, käynnistä rails server uudelleen**). Kirjautuminen onnistuu toistaiseksi vain niiden käyttäjien tunnuksilla joihin olet lisännyt salasanan konsolista käsin.

Lisätään vielä uuden käyttäjän luomiseen (eli näkymään view/users/_form.html.erb) salasanan syöttökenttä:

```erb
  <div class="field">
    <%= f.label :password %><br />
    <%= f.password_field :password %>
  </div>
  <div class="field">
    <%= f.label :password_confirmation %><br />
    <%= f.password_field :password_confirmation  %>
  </div>
```

Käyttäjien luomisesta huolehtivan kontrollerin apumetodia <code>user_params</code> on myös muutettava siten, että lomakkeelta lähetettyyn salasanaan ja sen varmenteeseen päästään käsiksi:

```erb
 def user_params
     params.require(:user).permit(:username, :password, :password_confirmation)
  end
```

Kokeile mitä tapahtuu, jos password confirmatioksi annetaan eri arvo kuin passwordiksi.

Huom: jos saat sisäänkirjautumisyrityksessä virheilmoitusen <code>BCrypt::Errors::InvalidHash</code> johtuu virhe melko varmasti siitä että käyttäjälle ei ole asetettu salasanaa. Eli aseta salasana konsolista ja yritä uudelleen.

> ## Tehtävä 10
>
> Tee luokalle User-validointi, joka varmistaa, että salasanan pituus on vähintää 4 merkkiä, ja että salasana sisältää vähintään yhden ison kirjaimen (voit unohtaa skandit) ja yhden numeron.

**Huom**: Säännöllisiä lausekkeita Rubyn tapaan voi testailla Rubular sovelluksella: http://rubular.com/


## Vain omien reittausten poisto

Tällä hetkellä kuka tahansa voi poistaa kenen tahansa reittauksia. Muutetaan sovellusta siten, että käyttäjä voi poistaa ainoastaan omia reittauksiaan. Tämä onnistuu helposti tarkastamalla asia reittauskontrollerissa:

```ruby
  def destroy
    rating = Rating.find params[:id]
    rating.delete if current_user == rating.user
    redirect_to :back
  end
```

eli tehdään poisto-operaatio ainoastaan, jos ```current_user``` on sama kuin reittaukseen liittyvä käyttäjä.

Reittauksen poistolinkkiä ei oikeastaan ole edes syytä näyttää muuta kuin kirjaantuneen käyttäjän omalla sivulla. Eli muutetaan käyttäjän show-sivua seuraavasti:

```erb
  <ul>
    <% @user.ratings.each do |rating| %>
      <li>
        <%= rating %>
        <% if @user == current_user %>
            <%= link_to 'delete', rating, method: :delete, data: { confirm: 'Are you sure?' } %>
        <% end %>
      </li>
    <% end %>
  </ul>
```

Huomaa, että pelkkä **delete**-linkin poistaminen ei estä poistamasta muiden käyttäjien tekemiä reittauksia, sillä on erittäin helppoa tehdä HTTP DELETE -operaatio mielivaltaisen reittauksen urliin. Tämän takia on oleellista tehdä kirjaantuneen käyttäjän tarkistus poistamisen suorittavassa kontrollerimetodissa.

> ## Tehtävä 11
>
> Kaikkien käyttäjien listalla [http://localhost:3000/users](http://localhost:3000/users) on nyt linkki **destroy**, jonka avulla käyttäjän voi tuhota, sekä linkki **edit** käyttäjän tietojen muuttamista varten. Poista molemmat linkit sivulta ja lisää ne (oikeastaan deleten siirto riittää, sillä edit on jo valmiina) käyttäjän sivulle.
>
> Näytä editointi- ja tuhoamislinkki vain kirjautuneen käyttäjän itsensä sivulla. Muuta myös User-kontrollerin metodeja <code>update</code> ja <code>destroy</code> siten, että olion tietojen muutosta tai poistoa ei voi tehdä kuin kirjaantuneena oleva käyttäjä itselleen.

> ## Tehtävä 12
>
> Luo uusi käyttäjätunnus, kirjaudu käyttäjänä ja tuhoa käyttäjä. Käyttäjätunnuksen tuhoamisesta seuraa ikävä virhe. **Pääset virheestä eroon tuhoamalla selaimesta cookiet.** Mieti mistä virhe johtuu ja korjaa asia myös sovelluksesta siten, että käyttäjän tuhoamisen jälkeen sovellus ei joudu virhetilanteeseen.

> ## Tehtävä 13
>
> Laajenna vielä sovellusta siten, että käyttäjän tuhoutuessa käyttäjän tekemät reittaukset tuhoutuvat automaattisesti. Ks. https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#orvot-oliot
>
> Jos teit tehtävät 7-8 eli toteutit järjestelmään olutkerhot, tuhoa käyttäjän tuhoamisen yhteydessä myös käyttäjän jäsenyydet olutkerhoissa


## Lisää hienosäätöä

Käyttäjän editointitoiminto mahdollistaa nyt myös käyttäjän <code>username</code>:n muuttamisen. Tämä ei ole ollenkaan järkevää. Poistetaan tämä mahdollisuus.

Uuden käyttäjän luominen ja käyttäjän editoiminen käyttävät molemmat samaa, tiedostossa views/users/_form.html.erb määriteltyä lomaketta. Alaviivalla alkavat näkymätemplatet ovat Railsissa ns. [partiaaleja](http://guides.rubyonrails.org/layouts_and_rendering.html#using-partials), joita liitetään muihin templateihin <code>render</code>-kutsun avulla.

Käyttäjän editointiin tarkoitettu näkymätemplate on seuraavassa:

```erb
<h1>Editing user</h1>

<%= render 'form' %>

<%= link_to 'Show', @user %> |
<%= link_to 'Back', users_path %>
```

eli ensin se renderöi _form-templatessa olevat elementit ja sen jälkeen pari linkkiä. Lomakkeen koodi on seuraava:

```erb
<%= form_for(@user) do |f| %>
  <% if @user.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(@user.errors.count, "error") %> prohibited this user from being saved:</h2>

      <ul>
      <% @user.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= f.label :username %><br>
    <%= f.text_field :username %>
  </div>
  <div class="field">
    <%= f.label :password %><br />
    <%= f.password_field :password %>
  </div>
  <div class="field">
    <%= f.label :password_confirmation %><br />
    <%= f.password_field :password_confirmation  %>
  </div>

  <div class="actions">
    <%= f.submit %>
  </div>
<% end %>

```

Haluaisimme siis poistaa lomakkeesta seuraavat

```erb
  <div class="field">
    <%= f.label :username %><br>
    <%= f.text_field :username %>
  </div>
```

_jos_ käyttäjän tietoja ollaan editoimassa, eli käyttäjäolio on jo luotu aiemmin.

Lomake voi kysyä oliolta <code>@user</code> onko se vielä tietokantaan tallentamaton metodin <code>new_record?</code> avulla. Näin saadaan <code>username</code>-kenttä näkyville lomakkeeseen ainoastaan silloin kuin kyseessä on uuden käyttäjän luominen:

```erb
  <% if @user.new_record? %>
    <div class="field">
      <%= f.label :username %><br />
      <%= f.text_field :username %>
    </div>
  <% end %>
```

Nyt lomake on kunnossa, mutta käyttäjänimeä on edelleen mahdollista muuttaa lähettämällä HTTP POST -pyyntö suoraan palvelimelle siten, että mukana on uusi username.

Tehdään vielä User-kontrollerin <code>update</code>-metodiin tarkastus, joka estää käyttäjänimen muuttamisen:

```ruby
  def update
    respond_to do |format|
      if user_params[:username].nil? and @user == current_user and @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

Muutosten jälkeen käyttäjän tietojen muuttamislomake näyttää seuraavalta:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-7.png)

> ## Tehtävä 14
>
> Ainoa käyttäjään liittyvä tieto on nyt salasana, joten muuta käyttäjän tietojen muuttamiseen tarkoitettua lomaketta siten, että se näyttää allaolevassa kuvassa olevalta. Huomaa, että uuden käyttäjän rekisteröitymisen (signup) on edelleen näytettävä samalta kuin ennen.

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w3-8.png)

## Ongelmia herokussa

Kun ohjelman päivitetty versio deployataan herokuun, törmätään jälleen ongelmiin. Kaikkien reittausten ja kaikkien käyttäjien sivu ja signup-linkki saavat aikaan tutun virheen:

![kuva](https://github.com/mluukkai/WebPalvelinohjelmointi2016/raw/master/images/ratebeer-w2-12.png)

Kuten [viime viikolla](
https://github.com/mluukkai/WebPalvelinohjelmointi2016/blob/master/web/viikko2.md#ongelmia-herokussa) jo totesimme, tulee ongelman syy selvittää herokun lokeista.

Kaikkien käyttäjien sivu aiheuttaa seuraavan virheen:

    ActionView::Template::Error (PG::UndefinedTable: ERROR:  relation "users" does not exist

eli tietokantataulua *users* ei ole olemassa koska sovelluksen uusia migraatioita ei ole suoritettu herokussa. Ongelma korjaantuu suorittamalla migraatiot:

    heroku run rake db:migrate

Myös signup-sivu toimii migraatioiden suorittamisen jälkeen.

Reittausten sivun ongelma ei korjaantunut migraatioiden avulla ja syytä on etsittävä lokeista:

```ruby
2016-01-24T19:19:58.672580+00:00 app[web.1]: ActionView::Template::Error (undefined method `username' for nil:NilClass):
2016-01-24T19:19:58.672582+00:00 app[web.1]:     2:
2016-01-24T19:19:58.672583+00:00 app[web.1]:     3: <ul>
2016-01-24T19:19:58.672584+00:00 app[web.1]:     4:   <% @ratings.each do |rating| %>
2016-01-24T19:19:58.672586+00:00 app[web.1]:     5:     <li> <%= rating %> <%= link_to rating.user.username, rating.user %> </li>
2016-01-24T19:19:58.672588+00:00 app[web.1]:     6:   <% end %>
2016-01-24T19:19:58.672589+00:00 app[web.1]:     7: </ul>
2016-01-24T19:19:58.672590+00:00 app[web.1]:     8:
```

Syy on jälleen tuttu, eli näkymäkoodi yrittää kutsua metodia <code>username</code> nil-arvoiselle oliolle. Syyn täytyy olla <code>link_to</code> metodissa oleva parametri

```ruby
    rating.user.username
```

eli järjestelmässä on reittauksia joihin ei liity user-olioa.

Vaikka tietokantamigraatio on suoritettu, on osa järjestelmän datasta edelleen vanhan tietokantaskeeman mukaista. Tietokantamigraation yheyteen olisikin ollut järkevää kirjoittaa koodi, joka varmistaa että myös järjestelmän data saatetaan migraation jälkeen sellaiseen muotoon, mitä koodi olettaa, eli että esim. jokaiseen olemassaolevaan reittaukseen liitetään joku käyttäjä tai käyttäjättömät reittaukset poistetaan.

Luodaan järjestelmään käyttäjä ja laitetaan herokun konsolista kaikkien olemassaolevien reittausten käyttäjäksi järjestelmään ensimmäisenä luotu käyttäjä:

```ruby
irb(main):002:0> u = User.first
=> #<User id: 1, username: "mluukkai", created_at: "2016-01-24 19:56:38", updated_at: "2016-01-24 19:56:38", password_digest: "$2a$10$g3AEFZtiOa186yfBql3tOO9ELAIgBUwOFnnWIVwwfYS...">
irb(main):003:0> Rating.all.each{ |r| u.ratings << r }
=> [#<Rating id: 1, score: 21, beer_id: 1, created_at: "2016-01-17 17:55:43", updated_at: "2016-01-24 19:56:51", user_id: 1>, #<Rating id: 2, score: 15, beer_id: 2, created_at: "2016-01-18 20:12:59", updated_at: "2016-01-24 19:56:51", user_id: 1>]
irb(main):004:0>
```

Nyt sovellus toimii.

Toistetaan vielä viikon lopuksi edellisen viikon "ongelmia herokussa"-luvun lopetus

<quote>
Useimmiten tuotannossa vastaan tulevat ongelmat johtuvat siitä, että tietokantaskeeman muutosten takia jotkut oliot ovat joutuneet epäkonsistenttiin tilaan, eli ne esim. viittaavat olioihin joita ei ole tai viitteet puuttuvat. **Sovellus kannattaakin deployata tuotantoon mahdollisimman usein**, näin tiedetään että mahdolliset ongelmat ovat juuri tehtyjen muutosten aiheuttamia ja korjaus on helpompaa.
</quote>

## Tehtävien palautus

Commitoi kaikki tekemäsi muutokset ja pushaa koodi Githubiin. Deployaa myös uusin versio Herokuun.

Tehtävät kirjataan palautetuksi osoitteeseen [http://wadrorstats2016.herokuapp.com](http://wadrorstats2016.herokuapp.com)
