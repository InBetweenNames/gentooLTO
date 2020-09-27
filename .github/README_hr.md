# GentooLTO overlej

[![Build Status](https://travis-ci.org/InBetweenNames/gentooLTO.svg?branch=master)](https://travis-ci.org/InBetweenNames/gentooLTO)
[![Gitter](https://badges.gitter.im/gentooLTO/community.svg)](https://gitter.im/gentooLTO/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[Engleski (English)](/README.md) | [Босански (Bosnian, Cyrillic)](README_bs-Cyril.md) | [Српски (Serbian)](README_sr.md) | [Bosanski (Bosnian, Latin)](README_bs-Latn.md)

---

Ovo je živi dokument. On će biti držan u korak sa projektom kako se projekat bude razvijao.

> Pažnja: ova podešavanja nisu za one slaboga srca. Najvjerovatnije nije pametna ideja da koristite ova podešavanja na proizvodnim sistemima! Usprkos mojoj boljoj procjeni, ja ih još uvijek koristim...

Da li vas zanima korištenje Gentoo-a (teoretski) maksimalnom brzinom? Želite li imati skoro u potpunosti [LTO-iziran](https://gcc.gnu.org/wiki/LinkTimeOptimization) sistem (engleski link)? Nastavite čitati da vidite kako se to može postići!

---

**Ova dokumentacija se premiješta u [GentooLTO Wiki](https://github.com/InBetweenNames/gentooLTO/wiki)**

---

## NOVO: Izvještaj pokrivenosti, 17. travanj 2019. godine

Na osnovu broja podnesaka iz ankete koja je bila u toku od 27. listopada 2018. godine, došli smo do sljedećih saznanja:

* ~27,4% Gentoo-ovog glavnog spremišta paketa je potvrđeno da radi sa GentooLTO-ovom zadanom konfiguracijom
* ~27% Gentoo-ovog glavnog spremišta paketa je potvrđeno da radi sa GentooLTO-ovom zadanom konfiguracijom bez ikakve potrebe za zaobilaznim rješenjima od strane GentooLTO-a

Ostatak paketa nije isproban, te je nepoznato koliko su podržani! Oni mogu, a i ne moraju raditi. Bilo bi odlično na kraju postići potpunu pokrivenost! Kako god bilo, po meni su ovi rezultati poprilično ohrabrujući.

Čitav izvještaj možete pogledati u pratećem [Gentoo članku (engleski link).](metadata/news/2019-04-17-results/2019-04-17-results.en.txt) Hvala svima koji su doprinijeli! Zasluge su na kraju članka.

Ako niste imali priliku išta podnijeti, nemojte se brinuti, još uvijek možete, ali će vaši rezultati tek biti uključeni u sljedećem izvještaju. Ja mislim da bi imalo smisla da se redovito (možda godišnje) održavaju.

## Uvod

Ovaj overlej sadrži niz konfiguracijskih datoteka koje se temelje na mojoj ličnoj Gentoo Portage konfiguraciji za omogućavanje LTO-a širom sistema. Namijenjen je za korištenje uz nasilne optimizacije od strane kompajlera da pomogne u hvatanju grešaka u programima (buba/bagova), uključujući u GCC-u. Ipak, može se također koristiti za obični LTO bez ikakvih nasilnih optimizacija od strane kompajlera. Nastavite čitati da saznate kako ga koristiti.

### Prošlost

Ranije tokom 2017. godine sam odlučio izvršiti jedan ogled, izgraditi Gentoo sistem koristeći `-O3` zastavu GCC kompajlera. Veoma je dobro dokumentirano na Gentoo wiki-ju da ovo nije poželjna konfiguracija, ali sam htio vidjeti u kojoj mjeri će se sistem srušiti. Kako se ispstavilo, većina paketa koji se ne mogu izgraditi sa `-O3` je već prisiljena u ebuild-ovima da se izgradi sa `-O2`, tako da sam iskusio poprilično mali broj neuspjeha. Zbog uspjeha kojeg sam imao koristeći `-O3`, odlučio sam načiniti stvari malo složenijim, te sam dodao [Graphite](https://gcc.gnu.org/wiki/Graphite) optimizacije (grafit; engleski link). Onda sam postao malo odvažniji i još dodao LTO. Nakon što sam radio ovo otprilike osam mjeseci, osjećao sam se dovoljno dobro u vezi svoje konfiguracije, te sam odlučio da ju objavim da ju mogu vidjeti oni koje to zanima. Ovaj overlej će biti aktivno ažuriran i ispitivan, pošto se temelji na mojoj Portage konfiguraciji.

---

Moji izvorni LTO i Graphite ogledi su se temeljili na [ovom korisnom blog članku.](http://yuguangzhang.com/blog/enabling-gcc-graphite-and-lto-on-gentoo/) Šta ovaj overlej postiže jeste proširenje sadržaja iz tog članka sa aktivnom i ažuriranom konfiguracijom.

---

## Filozofija ovog overleja

[To be translated]
