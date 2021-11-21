# cvs-location-closures

CVS is [closing 10% of its stores over the next 3 years](https://www.cnn.com/2021/11/18/investing/cvs-store-closures/index.html) despite:

- gross profit for the quarter ending September 30, 2021 was $28.783B, a 10.21% increase year-over-year
- gross profit for the twelve months ending September 30, 2021 was $113.184B, a 10.48% increase year-over-year
- annual gross profit for 2020 was $104.725B, a 6.8% increase from 2019
- annual gross profit for 2019 was $98.057B, a 157.15% increase from 2018
- annual gross profit for 2018 was $38.132B, a 21.68% increase from 2017

Since all these types of giant mega corps are pretty much evil at the core and also do everything possible to make their store closing lists hard to get or non-machine-readable, we're going to assume they will at least remove them from their online store locator. Thus, we'll scrape them every month starting in 2022.

Why?

I suspect they will be removing stores from rural areas and poor/minority city areas (b/c "evil") creating health/retail deserts (and, to a degree, contribute to the growing food desert problem).

The repo format will change a bit once the scraping gets started for realz but I wanted to get `data/cvs.csv` initially created and geocoded (ref: `data/cvs-address_geocodio_10effd70f9b9148ff2beccb58e8bf1b924fce9a4.csv`) so I could plan for 2022.

### NOTE

CVS setup some aggressive anti-scraping components during the initial vaccine rollout b/c lots of folks were abusing automation to get an appointment (b/c the U.S. response to the COVID-19 crisis has been and continues to be abysmal).

DO NOT just run code the way it is or at least don't run it at home b/c you may get your IP banned from actually using the CVS site proper. It's cheap to run it from the cyber armpit (a.k.a. cyber New Jersey) of the internet (a.k.a. DigitalOcean).
