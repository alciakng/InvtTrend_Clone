# 📄 Inventory Turnover Trends Clone (Stata Replication)

## Overview
This repository contains the **Stata-based replication ("clone") code** for the inventory turnover trend analysis presented in the paper:

> **Paper Title:**  
> *Inventory Turnover Trends in the U.S. Retail Industry, 1985–2015*  
> **Authors:** [Author names]  
> **Published in:** [Journal Name]

The code replicates the key empirical analyses, including:
- Calculation of inventory turnover (IT) at the firm-year level
- Cleaning and filtering of Compustat data (quarterly and annual)
- Regression models with **firm fixed effects** and **year fixed effects**
- Estimation of trends in inventory turnover before and after 2000
- Generation of figures and tables comparable to those presented in the original study

---

## Requirements
- **Stata 17 or later** (recommended for `reghdfe`, `esttab`, `estout` commands)
- **reghdfe** package installed
- **estout** package installed

---

## How to Run
1. Download and prepare Compustat quarterly and annual datasets.
2. Place raw data under same directory.
3. Execute `.do` files sequentially from `/DO_files/`.
4. Outputs (tables and figures) will be saved to the working directory.

---

## Notes
- The codes assume familiarity with Compustat variable names (e.g., `invtq`, `saleq`, `cogsq` for quarterly data).
- If you do not have WRDS access, you will not be able to fully replicate the results.
- This repository is intended **solely for educational and research purposes**.

---

## License
Distributed under the **MIT License**.

---

## Disclaimer
This repository is an independent Stata clone of the original empirical work.  
It is **not affiliated** with the original authors or publishers.

---
