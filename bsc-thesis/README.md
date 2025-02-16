# Impact of financed emissions constraints on the composition of an optimal investment portfolio

In this bachelor's thesis project, I collected, cleaned, and analysed a dataset of 1000+ enterprises to assess the impact of financed emissions constraints on investment portfolio returns. This folder contains the source code for conducting these analyses and optimization.

The code is divided in four separate Jupyter notebooks:
##### 1_market_price_daily_to_monthly.ipynb
- Reads daily stock market prices from multiple countries from separate files
- Transforms daily prices to monthly prices
- Converts all files to the same currency and combines all countries' data into a single dataframe
##### 2_market_price_analysis.ipynb
- Computes descriptive statistics and fits distributions to the return series of individual companies
- Compares the performance of the sampled companies to market indexes
##### 3_scenario_creation.ipynb
- Fits a copula to the data and simulates future return scenarios
##### 4_portfolio_opt.ipynb
- Defines the optimization model
- Performs out-of-sample testing of the optimal portfolio compositions

The data are not available, so the code output can not be replicated.

The finalized thesis "Impact of financed emissions constraints on the composition of an optimal investment portfolio" is available to read at [https://sal.aalto.fi/publications/pdf-files/theses/bac/tnor23_public.pdf](https://sal.aalto.fi/publications/pdf-files/theses/bac/tnor23_public.pdf)

Publication date: 28.9.2023