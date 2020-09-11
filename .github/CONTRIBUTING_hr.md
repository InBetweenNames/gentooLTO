# Doprinosi

Doprinosi su dobrodošli. Zbog prirode Portage-a, spajanje promijena bi moglo biti poteško, posebno pošto se očekuje da korisnici uzmu od ove konfiguracije jedino ono što oni nađu korisnim. Promjene u USE zastavama, na primjer, vjerovatno neće biti prihvaćene, dok bi promjene u zastavama kompajlera mogle biti, posebno ako daju kompajleru više slobode da pravi odluke. Doprinosi moraju održati filozofiju navedenu u [README-u](README_bs_Lat.md). Doprinosi koji nadjačavaju kompajlerovu bolju prosudbu će biti odbijeni.

## Smjernice za zahtjeve za povlačenje

Kod stvaranja zahtjeva, naslov bi trebao biti:

~~~ text 
<kategorija>/<paket>: <izvršni sažetak>
~~~

Ako zahtjev dodaje nešto u `ltoworkarounds.conf`, pobrinite se da ima komentar pored relevantnih linija koji objašnjava problem s kojim ste se susreli.

Ako zahtjev sadrži zakrpu koja omogućava da se program izgradi sa optimizacijama iz ovog overleja, poželjno je da je zakrpa korisnička zakrpa i da se nalazi u `patches` direktoriji, postepeno povećavajući broj revizije paketa `sys-config/lotize` po potrebi.

Za sve ostale zahtjeve je preporučeno da prvo napravite karticu u pratiocu grešaka kako bismo mogli razgovarati o problemu koji se riješava i o pristupu rješavanju problema. Ovo spremište je, na kraju krajeva, oblikovano ovim principom, tako da najbolje rješenje ispliva na površinu. Ako ne želite da napravite karticu, može te mi također i izravno poslati e-poštu.
