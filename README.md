# 📄 Inventory Turnover Trends Clone (Stata Replication)

## Overview
This repository contains the **Stata-based replication ("clone") code** for the inventory turnover trend analysis presented in the paper:

If you use this repository or find it helpful, please cite the original paper
> Gallino, Santiago, and Antonio Moreno. 2014.  
> "Integration of Online and Offline Channels in Retail: The Impact of Sharing Reliable Inventory Availability Information."  
> *Management Science* 60(6): 1434–1451.  
> https://doi.org/10.1287/mnsc.2014.1951

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
3. Execute `.do` files sequentially from root directory.
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

## Table&Figure Replication 


### Table2 Replication

##### before 2000 (1985~2000)
<img width="884" alt="image" src="https://github.com/user-attachments/assets/41b13244-8212-4c1a-9417-04e3260977bb" />
<img width="886" alt="image" src="https://github.com/user-attachments/assets/117a5743-f33a-40c0-85a0-36beaccad6d4" />
<img width="719" alt="image" src="https://github.com/user-attachments/assets/44a6c673-12cc-4703-9e5f-d81f0701c902" />
<img width="719" alt="image" src="https://github.com/user-attachments/assets/5b8b49a5-451d-4982-8163-521fed330e2b" />


##### after 2000 (2001~2015)
<img width="886" alt="image" src="https://github.com/user-attachments/assets/c3b59762-a515-41d1-8250-fb43aa3318d0" />
<img width="886" alt="image" src="https://github.com/user-attachments/assets/a7ebc88e-3219-4243-93ce-fdd02398b467" />
<img width="719" alt="image" src="https://github.com/user-attachments/assets/6ca87043-495a-4734-a472-5713d66fd314" />
<img width="718" alt="image" src="https://github.com/user-attachments/assets/e97d72ca-cfd4-45eb-95c9-e424d358e052" />



### Table4 Replication 

#### before 2000 (1985~2000)
<img width="886" alt="image" src="https://github.com/user-attachments/assets/69d8370f-c832-440a-b2cc-00d2dc0d675c" />

#### after 2000 (2001~2015)
<img width="880" alt="image" src="https://github.com/user-attachments/assets/6196d831-21fd-4d78-a32b-c0421ff06f70" />


### Table5 Replication

#### before 2000 (1985~2000)
<img width="430" alt="image" src="https://github.com/user-attachments/assets/db3dacda-708a-4d45-aa06-f650cb4ab1d3" />

#### after 2000 (2001~2015)
<img width="414" alt="image" src="https://github.com/user-attachments/assets/513079c7-a9da-4066-b8b0-ec158120a4c3" />


### Figure2 Replication

#### before 2000 (1985~2000)
<img width="809" alt="image" src="https://github.com/user-attachments/assets/aa7e8ed7-b398-4644-b119-beb05d79a1d4" />

#### after 2000 (2001~2015)
<img width="800" alt="image" src="https://github.com/user-attachments/assets/15d886bf-bc76-4b0f-a86e-40f889449888" />


### Table6 Replicaiton

#### before 2000 (1985~2000)
<img width="502" alt="image" src="https://github.com/user-attachments/assets/c3ae9096-5697-4bdc-b2e3-45f9ed9e7e6d" />

#### after 2000 (2001~2015)
<img width="513" alt="image" src="https://github.com/user-attachments/assets/2d489a55-205c-4780-8801-352b3f57befb" />


## Report for replication project

![Image](https://github.com/user-attachments/assets/c522c7a0-86c0-4ac0-ae24-a8b2a253b1c5)
![Image](https://github.com/user-attachments/assets/18353168-c9ce-47a0-ada5-f4b7e40bcf37)
![Image](https://github.com/user-attachments/assets/8430c5d1-9f57-4b13-a217-5643e5b38807)
![Image](https://github.com/user-attachments/assets/1d37c513-7ac3-42e4-bca2-4a81a392730e)
![Image](https://github.com/user-attachments/assets/8067ebba-c991-44c4-8935-7a897e5d0b46)
![Image](https://github.com/user-attachments/assets/1f9a1de9-a725-422d-abff-ed5b2d6203c2)
![Image](https://github.com/user-attachments/assets/fd65c141-babe-4361-af93-912ac888cb96)


