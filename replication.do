
/*===========================================
 <Section 1. 프레임 정제>
 [Part1] year 프레임 결측치 제거
 [Part2] quarter 프레임 결측치 제거 
 [Part3] quarter 프레임의 4분기 평균 통계량산출(invtq, ppegtq)
 [Part4] 데이터프레임 merge
 [Part5] 결측치 및 이상치 제거 작업들
 
 <결측치제거 조건 명세> 
 - (1번) 결측치 제거 
 - (2번) 5년 연속 데이터가 없는 경우 제거 
 - (3번) 예상매출액 컬럼 생성 
 - (4번) 회사별 최초 2개년 데이터 제거
=============================================*/

// 프레임 생성
frame create pre2000_year
frame create pre2000_quarter
frame create post2000_year
frame create post2000_quarter

// ----------------------------------------------
// [Part1] year프레임 결측치제거 
// ----------------------------------------------

// 1985~2000 년도 프레임 / 결측치 제거 
frame pre2000_year: {
    use year, clear
    keep if fyear >=1985 & fyear <= 2000 
	
	// cogs 또는 sale 중 하나라도 결측치면 삭제 (1번 조건)
    drop if missing(cogs) | missing(sale)
}

// describe 
frame pre2000_year : describe

// 2000~2015 년도 프레임 / 결측치 제거  
frame post2000_year: {
	use year, clear
    keep if fyear >= 2001
	
	// cogs 또는 sale 중 하나라도 결측치면 삭제 (1번 조건)
    drop if missing(cogs) | missing(sale)
}

// describe
frame post2000_year : describe

// ----------------------------------------------
// [Part2] quarter 프레임의 결측치 정제 
// ----------------------------------------------

// 1985~2000년 분기 프레임 / 결측치 및 정제 
frame pre2000_quarter: {
    use quarter,clear
    keep if fyear >=1985 & fyear <=2000
	
	//--------------------------------------------
    // (1번) 재고자산 또는 고정자산이 모두 결측인 경우 제거
	//--------------------------------------------
	
	// 그룹 아이디 태그 생성
	egen group_id = group(gvkey sic fyear)
	egen n_obs = count(fqtr), by(group_id)
	
    // 조건 1: invtq가 모두 0 또는 결측
    gen invtq_bad = missing(invtq) | invtq == 0
    egen invtq_sum = total(invtq_bad), by(group_id)
    gen invtq_flag = (invtq_sum == n_obs)

    // 조건 2: ppegtq가 모두 0 또는 결측
    gen ppegtq_bad = missing(ppegtq) | ppegtq == 0
    egen ppegtq_sum = total(ppegtq_bad), by(group_id)
    gen ppegtq_flag = (ppegtq_sum == n_obs)
	
	// drop flag 생성
	gen drop_group = invtq_flag | ppegtq_flag
	
	// 그룹 전체 삭제 (flag가 1인 그룹 전체 drop)
	egen keep_flag = max(drop_group), by(group_id)
    drop if keep_flag == 1
	
	// 조건 3: 0인 값은 결측치로 대체 
	replace invtq = . if invtq == 0
	replace ppegtq = . if ppegtq == 0
	
	// 정리
    drop group_id invtq_bad invtq_flag ppegtq_bad ppegtq_flag drop_group
}

// describe 
frame pre2000_quarter : describe


frame post2000_quarter: {
    use quarter,clear
    keep if fyear >=2001
	
	//---------------------------------------------
    // (1번) 재고자산 또는 고정자산이 모두 결측인 경우 제거
	//---------------------------------------------
	
	// 그룹 아이디 태그 생성
	egen group_id = group(gvkey sic fyear)
	egen n_obs = count(fqtr), by(group_id)
	
    // 조건 1: invtq가 모두 0 또는 결측
    gen invtq_bad = missing(invtq) | invtq == 0
    egen invtq_sum = total(invtq_bad), by(group_id)
    gen invtq_flag = (invtq_sum == n_obs)

    // 조건 2: ppegtq가 모두 0 또는 결측
    gen ppegtq_bad = missing(ppegtq) | ppegtq == 0
    egen ppegtq_sum = total(ppegtq_bad), by(group_id)
    gen ppegtq_flag = (ppegtq_sum == n_obs)
	
	// drop flag 생성
	gen drop_group = invtq_flag | ppegtq_flag
	
	// 그룹 전체 삭제 (flag가 1인 그룹 전체 drop)
	egen keep_flag = max(drop_group), by(group_id)
    drop if keep_flag == 1
	
	// 0인 값은 결측치로 대체 
	replace invtq = . if invtq == 0
	replace ppegtq = . if ppegtq == 0
	
	// 정리
    drop group_id invtq_bad invtq_flag ppegtq_bad ppegtq_flag drop_group
}

// describe 
frame post2000_quarter : describe

// ----------------------------------------------
// [Part3] quarter 프레임의 4분기 평균 통계량산출(invtq, ppegtq)
// ----------------------------------------------
frame pre2000_quarter {
	preserve
    collapse (mean) invtq ppegtq, by(gvkey sic fyear)
    frame put gvkey fyear invtq ppegtq sic, into(pre2000_quarter_mean)
	restore
}

// quarter 프레임의 4분기 평균 통계량산출(invtq, ppegtq)
frame post2000_quarter {
	preserve
    collapse (mean) invtq ppegtq, by(gvkey sic fyear)
    frame put gvkey fyear invtq ppegtq sic, into(post2000_quarter_mean)
	restore
}

// describe 
frame pre2000_quarter_mean : describe
// describe 
frame post2000_quarter_mean : describe


// ----------------------------------------------
// [Part4] frame merge
// ----------------------------------------------
frame copy pre2000_year pre2000_merge
frame change pre2000_merge // 머지용 테이블로 전환 
frame pre2000_quarter_mean: rename fyearq fyear // 조인을 위해 컬럼명변경 
frlink 1:1 gvkey fyear sic, frame(pre2000_quarter_mean) // 조인 
frget invtq ppegtq, from(pre2000_quarter_mean) // 컬럼 가져오기
rename (invtq ppegtq) (mean_invt mean_ppegt)

frame copy post2000_year post2000_merge
frame change post2000_merge // 머지용 테이블로 전환 
frame post2000_quarter_mean: rename fyearq fyear // 조인을 위해 컬럼명변경 
frlink 1:1 gvkey fyear sic, frame(post2000_quarter_mean) // 조인 
frget invtq ppegtq, from(post2000_quarter_mean) // 컬럼 가져오기
rename (invtq ppegtq) (mean_invt mean_ppegt)

// describe 
frame pre2000_merge : describe
// describe 
frame post2000_merge : describe


// ----------------------------------------------
// [Part5] 결측치 및 이상치 제거 작업들
// ----------------------------------------------

// ---------------------
// (1번) 조인 후 결측치 제외 
// ---------------------
frame pre2000_merge: drop if missing(mean_invt) | missing(mean_ppegt)
frame post2000_merge: drop if missing(mean_invt) | missing(mean_ppegt)


// ---------------------------------------
// (2번) 5년 연속 데이터가 존재하지 않는 기업들 제외 
// ---------------------------------------

frame pre2000_merge: {
    
    // 1. 정렬
    gsort gvkey fyear

    // 2. 연속 연도 여부 확인 (전 연도 +1인지)
    gen is_consec = (fyear == fyear[_n-1] + 1 & gvkey == gvkey[_n-1])

    // 3. 연속 streak 계산 (by + replace)
    gen streak = 1
    by gvkey (fyear): replace streak = streak[_n-1] + 1 if is_consec == 1

    // 4. 기업별 최대 연속 연도 수 계산
    egen max_streak = max(streak), by(gvkey)

    // 5. 5년 연속 기록 없는 기업 제거
    keep if max_streak >= 5

    // 6. 정리 (불필요 변수 삭제)
    drop is_consec streak max_streak
}

frame post2000_merge: {
    
    // 1. 정렬
    gsort gvkey fyear

    // 2. 연속 연도 여부 확인 (전 연도 +1인지)
    gen is_consec = (fyear == fyear[_n-1] + 1 & gvkey == gvkey[_n-1])

    // 3. 연속 streak 계산 (by + replace)
    gen streak = 1
    by gvkey (fyear): replace streak = streak[_n-1] + 1 if is_consec == 1

    // 4. 기업별 최대 연속 연도 수 계산
    egen max_streak = max(streak), by(gvkey)

    // 5. 5년 연속 기록 없는 기업 제거
    keep if max_streak >= 5

    // 6. 정리 (불필요 변수 삭제)
    drop is_consec streak max_streak
}


// -----------------------------------
// (3번 조건) 예상매출액 계산하여 컬럼 생성 
// -----------------------------------
frame pre2000_merge: {

    // 1. 정렬
    gsort gvkey fyear

    // 2. 필요 변수 생성
    gen L = .
    gen T = .
    gen forecast_sales = .
    gen S = sale   // 실제 매출

    // 3. 회사별 연도 순서 (1,2,...)
    by gvkey (fyear): gen year_idx = _n

    // 4. 평활 상수 설정
    local alpha = 0.75
    local gamma = 0.75

    // 5. 초기값 설정 (1번째 해)
    by gvkey (fyear): replace L = S if year_idx == 1
    by gvkey (fyear): replace T = S[_n+1] - S[_n] if year_idx == 1

    // 6. 연도별 루프 계산 (2번째 연도부터 순차적으로 갱신)
    quietly {
        gen L_new = .
        gen T_new = .

        forvalues i = 2/100 {  // 충분히 큰 값으로 반복, 데이터 없으면 자동 break
            count if year_idx == `i'
            if r(N) == 0 continue, break

            by gvkey (fyear): replace L_new = `alpha' * S + (1 - `alpha') * (L[_n-1] + T[_n-1]) if year_idx == `i'

            by gvkey (fyear): replace T_new = `gamma' * (L_new - L[_n-1]) + (1 - `gamma') * T[_n-1] if year_idx == `i'

            by gvkey (fyear): replace forecast_sales = L[_n-1] + T[_n-1] if year_idx == `i'

            replace L = L_new if year_idx == `i' & !missing(L_new)
            replace T = T_new if year_idx == `i' & !missing(T_new)
        }
    }

    // 7. 정리
    drop L T L_new T_new S
	
	// -------------------------------
    // 8. (4번 조건) 최초 2개년 데이터 삭제 
	// -------------------------------
    drop if year_idx <= 2
    drop year_idx
}

frame post2000_merge: {

    // 1. 정렬
    gsort gvkey fyear

    // 2. 필요 변수 생성
    gen L = .
    gen T = .
    gen forecast_sales = .
    gen S = sale   // 실제 매출

    // 3. 회사별 연도 순서 (1,2,...)
    by gvkey (fyear): gen year_idx = _n

    // 4. 평활 상수 설정
    local alpha = 0.75
    local gamma = 0.75

    // 5. 초기값 설정 (1번째 해)
    by gvkey (fyear): replace L = S if year_idx == 1
    by gvkey (fyear): replace T = S[_n+1] - S[_n] if year_idx == 1

    // 6. 연도별 루프 계산 (2번째 연도부터 순차적으로 갱신)
    quietly {
        gen L_new = .
        gen T_new = .

        forvalues i = 2/100 {  // 충분히 큰 값으로 반복, 데이터 없으면 자동 break
            count if year_idx == `i'
            if r(N) == 0 continue, break

            by gvkey (fyear): replace L_new = `alpha' * S + (1 - `alpha') * (L[_n-1] + T[_n-1]) if year_idx == `i'

            by gvkey (fyear): replace T_new = `gamma' * (L_new - L[_n-1]) + (1 - `gamma') * T[_n-1] if year_idx == `i'

            by gvkey (fyear): replace forecast_sales = L[_n-1] + T[_n-1] if year_idx == `i'

            replace L = L_new if year_idx == `i' & !missing(L_new)
            replace T = T_new if year_idx == `i' & !missing(T_new)
        }
    }

    // 7. 정리
    drop L_new T_new S

	// -------------------------------
    // 8. (4번 조건) 최초 2개년 데이터 삭제 
	// -------------------------------
    drop if year_idx <= 2
    drop year_idx
}




/*=================================================================================
 <Section 2. 파생변수 생성>
 [Part1. 산업코드(SIC) 그룹분류]
 [Part2. 파생변수 생성]
 - 1. 재고회전율(IT) - cogs(연간매출원가)/invtq(연평균 재고자산) 
 - 2. 총이익률(GM) - (sale(매출액) - cogs(매출원가)) / sale(매출액)
 - 3. 자본집약도(CI) - ppegtq(연평균 고정자산)/(invtq(연평균 재고자산) + ppegtq(연평균 고정자산))
 - 4. 매출서프라이즈(SS) - sale(매출액) / forcast_sales(예상매출액)
 [Part3. 파생변수 이상치 제거]
===================================================================================*/
// [Part1. 산업코드(SIC) 그룹분류]
frame pre2000_merge: {

    // 1. 문자형 파생변수 생성
    gen str50 industry_segment = ""

    // 2. 세그먼트 할당 조건
    replace industry_segment = "Apparel and accessory stores"            if substr(sic, 1, 2) == "56"
    replace industry_segment = "Catalog, mail-order houses"              if sic == "5961"
    replace industry_segment = "Department stores"                       if sic == "5311"
    replace industry_segment = "Drug and proprietary stores"             if sic == "5912"
    replace industry_segment = "Food stores"                             if inlist(sic, "5400", "5411")
    replace industry_segment = "Hobby, toy, and game shops"              if sic == "5945"
    replace industry_segment = "Home furniture and equip stores"         if sic == "5700"
    replace industry_segment = "Jewelry stores"                          if sic == "5944"
    replace industry_segment = "Radio, TV, consumer electronics stores"  if sic == "5731"
    replace industry_segment = "Variety stores"                          if sic == "5331"
}

frame post2000_merge: {

    // 1. 문자형 파생변수 생성
    gen str50 industry_segment = ""

    // 2. 세그먼트 할당 조건
    replace industry_segment = "Apparel and accessory stores"            if substr(sic, 1, 2) == "56"
    replace industry_segment = "Catalog, mail-order houses"              if sic == "5961"
    replace industry_segment = "Department stores"                       if sic == "5311"
    replace industry_segment = "Drug and proprietary stores"             if sic == "5912"
    replace industry_segment = "Food stores"                             if inlist(sic, "5400", "5411")
    replace industry_segment = "Hobby, toy, and game shops"              if sic == "5945"
    replace industry_segment = "Home furniture and equip stores"         if sic == "5700"
    replace industry_segment = "Jewelry stores"                          if sic == "5944"
    replace industry_segment = "Radio, TV, consumer electronics stores"  if sic == "5731"
    replace industry_segment = "Variety stores"                          if sic == "5331"
}


// [Part2. 파생변수 생성]
frame pre2000_merge: {

    // 1. 재고회전율 (Inventory Turnover, IT)
    gen IT = cogs / mean_invt if !missing(cogs, mean_invt) & mean_invt != 0

    // 2. 총이익률 (Gross Margin, GM)
    gen GM = (sale - cogs) / sale if !missing(sale, cogs) & sale != 0

    // 3. 자본집약도 (Capital Intensity, CI)
    gen CI = mean_ppegt / (mean_invt + mean_ppegt) if !missing(mean_ppegt, mean_invt) & (mean_invt + mean_ppegt) != 0

    // 4. 매출서프라이즈 (Sales Surprise, SS)
    gen SS = sale / forecast_sales if !missing(sale, forecast_sales) & forecast_sales != 0
}

frame post2000_merge: {

    // 1. 재고회전율 (Inventory Turnover, IT)
    gen IT = cogs / mean_invt if !missing(cogs, mean_invt) & mean_invt != 0

    // 2. 총이익률 (Gross Margin, GM)
    gen GM = (sale - cogs) / sale if !missing(sale, cogs) & sale != 0

    // 3. 자본집약도 (Capital Intensity, CI)
    gen CI = mean_ppegt / (mean_invt + mean_ppegt) if !missing(mean_ppegt, mean_invt) & (mean_invt + mean_ppegt) != 0

    // 4. 매출서프라이즈 (Sales Surprise, SS)
    gen SS = sale / forecast_sales if !missing(sale, forecast_sales) & forecast_sales != 0
}



// [Part3. 파생변수 이상치 제거]
frame pre2000_merge: {

    // 1. IT 변수의 평균과 표준편차 계산
    summarize IT
    local mean_IT = r(mean)
    local sd_IT = r(sd)
    
    // 2. 3표준편차 기준으로 이상치 플래그 생성
    gen IT_outlier = (IT < `mean_IT' - 3*`sd_IT') | (IT > `mean_IT' + 3*`sd_IT')
    
    // 3. 이상치 제거
    drop if IT_outlier == 1
    
    // 4. 플래그 변수 삭제 (깔끔하게 정리)
    drop IT_outlier
}

frame post2000_merge: {

    // 1. IT 변수의 평균과 표준편차 계산
    summarize IT
    local mean_IT = r(mean)
    local sd_IT = r(sd)
    
    // 2. 3표준편차 기준으로 이상치 플래그 생성
    gen IT_outlier = (IT < `mean_IT' - 3*`sd_IT') | (IT > `mean_IT' + 3*`sd_IT')
    
    // 3. 이상치 제거
    drop if IT_outlier == 1
    
    // 4. 플래그 변수 삭제 (깔끔하게 정리)
    drop IT_outlier
}



/*=================================================================================
 <Section 3. 논문 Replication>
 - 문제 3.a : [Table 2] Summary Statistics of the Variables for Each Retail Segment
 - 문제 3.b : [Table 4] Coefficients' Estimates for Models (1) and (2)
			 (1) Model (1): Run OLS for each segments (i.e., repeat 10 times)
			 (2) Model (2): Run OLS for entire segments
 - 문제 3.c : [Table 5] Estimates of Time-Specific Fixed Effects for Models (1) and (2)
 - 문제 3.d : [Figure 2] Plot of Time-Specific Fixed Effects for Model (2) [5 points]
 - 문제 3.e : [Table 6] Time Trends in IT, CI, and GM Estimated Using Equation (5)
===================================================================================*/
// --------------------------------------------------------------------------------
// 문제 3.a : [Table 2] Summary Statistics of the Variables for Each Retail Segment
// --------------------------------------------------------------------------------
 
// 원본 프레임에서 모든 요약 통계를 계산 → 새로운 프레임에 저장
frame pre2000_merge: {

	// 1. 회사 수 계산을 위한 임시 프레임
	preserve
		 // 1. 각 기업별 첫 행만 남기는 tag 생성
		 egen tag = tag(industry_segment gvkey)
		 // 그 행들만 남김
		 keep if tag == 1
		 // 2. dummy 변수 생성해서 count할 값으로 사용
		 gen one = 1
		 // 3. 산업별 고유 기업 수 count
		 collapse (count) firms = one, by(industry_segment)
		 tempfile firmcount
		 save "firmcount.dta", replace

	restore 
	 
	// 2. 요약 통계량 계산
	preserve
		 gen one = 1
			 
		 collapse ///
			 (count) obs = one ///
			 (mean)  mean_sale = sale mean_IT = IT mean_GM = GM mean_CI = CI ///
			 (sd)    sd_IT = IT sd_GM = GM sd_CI = CI ///
			 (p50)   med_sale = sale med_IT = IT med_GM = GM med_CI = CI ///
			, by(industry_segment)

		 // 3. firm 수 결합
		 merge 1:1 industry_segment using "firmcount.dta", nogenerate

		 // 4. CV 계산
		 gen cv_IT = sd_IT / mean_IT
		 gen cv_GM = sd_GM / mean_GM
		 gen cv_CI = sd_CI / mean_CI
					 
		 // 5. Aggregate 행 추가를 위해 임시저장 
		 tempfile summary_stats
		 save "summary_stats.dta", replace

	restore
 
	// 3. 집계값 계산용 프레임 복사
	preserve
	 
		 use "summary_stats.dta", clear
		 collapse ///
				 (sum) firms obs ///
				 (mean) mean_sale mean_IT mean_GM mean_CI ///
							sd_IT sd_GM sd_CI ///
							med_sale med_IT med_GM med_CI ///
							cv_IT cv_GM cv_CI
		 gen industry_segment = "Aggregate statistics"
		 append using "summary_stats.dta"
	 
		 // 6. 결과를 요약 프레임으로 복사
		 frame put industry_segment firms obs ///
			 mean_sale mean_IT mean_GM mean_CI ///
			 sd_IT sd_GM sd_CI ///
			 med_sale med_IT med_GM med_CI ///
			 cv_IT cv_GM cv_CI, ///
			 into(pre2000_summary)

	restore
         
	frame change pre2000_summary 

	// 4. Aggregate statistics 마지막 줄로 보내기 
	gen sort_order = cond(industry_segment == "Aggregate statistics", _N + 1, _n)
	sort sort_order
	drop sort_order

	// 5. 출력
	list industry_segment firms obs mean_sale mean_IT mean_GM mean_CI, sep(0) noobs abbrev(10) //평균
	list industry_segment firms obs med_sale med_IT med_GM med_CI, sep(0) noobs abbrev(10) //중앙값 
	list industry_segment firms obs sd_IT sd_GM sd_CI, sep(0) noobs abbrev(10) // 표준편차 
	list industry_segment firms obs cv_IT cv_GM cv_CI, sep(0) noobs abbrev(10) // 변동계수
}

// 원본 프레임에서 모든 요약 통계를 계산 → 새로운 프레임에 저장
frame post2000_merge: {
 
	// 1. 회사 수 계산을 위한 임시 프레임
	preserve

		 // 1. 각 기업별 첫 행만 남기는 tag 생성
		 egen tag = tag(industry_segment gvkey)
		 // 그 행들만 남김
		 keep if tag == 1

		 // 2. dummy 변수 생성해서 count할 값으로 사용
		 gen one = 1
		 // 3. 산업별 고유 기업 수 count
		 collapse (count) firms = one, by(industry_segment)
		 tempfile firmcount
		 save "firmcount.dta", replace

	restore 
 
	// 2. 요약 통계량 계산
	preserve
		 gen one = 1
			 
		 collapse ///
			 (count) obs = one ///
			 (mean)  mean_sale = sale mean_IT = IT mean_GM = GM mean_CI = CI ///
			 (sd)    sd_IT = IT sd_GM = GM sd_CI = CI ///
			 (p50)   med_sale = sale med_IT = IT med_GM = GM med_CI = CI ///
			, by(industry_segment)

		 // 3. firm 수 결합
		 merge 1:1 industry_segment using "firmcount.dta", nogenerate

	 
		 // 4. CV 계산
		 gen cv_IT = sd_IT / mean_IT
		 gen cv_GM = sd_GM / mean_GM
		 gen cv_CI = sd_CI / mean_CI
					 
		 // 5. Aggregate 행 추가를 위해 임시저장 
		 tempfile summary_stats
		 save "summary_stats.dta", replace

	restore
 

	// 3. 집계값 계산용 프레임 복사
	preserve

		 use "summary_stats.dta", clear
		 collapse ///
				 (sum) firms obs ///
				 (mean) mean_sale mean_IT mean_GM mean_CI ///
							sd_IT sd_GM sd_CI ///
							med_sale med_IT med_GM med_CI ///
							cv_IT cv_GM cv_CI
		 gen industry_segment = "Aggregate statistics"
		 append using "summary_stats.dta"
	 
		 // 6. 결과를 요약 프레임으로 복사
		 frame put industry_segment firms obs ///
			 mean_sale mean_IT mean_GM mean_CI ///
			 sd_IT sd_GM sd_CI ///
			 med_sale med_IT med_GM med_CI ///
			 cv_IT cv_GM cv_CI, ///
			 into(post2000_summary)

	restore
			 
	frame change post2000_summary 

	// 4. Aggregate statistics 마지막 줄로 보내기 
	gen sort_order = cond(industry_segment == "Aggregate statistics", _N + 1, _n)
	sort sort_order
	drop sort_order

	// 5. 출력
	frame change post2000_summary
	list industry_segment firms obs mean_sale mean_IT mean_GM mean_CI, sep(0) noobs abbrev(10) //평균
	list industry_segment firms obs med_sale med_IT med_GM med_CI, sep(0) noobs abbrev(10) //중앙값 
	list industry_segment firms obs sd_IT sd_GM sd_CI, sep(0) noobs abbrev(10) // 표준편차 
	list industry_segment firms obs cv_IT cv_GM cv_CI, sep(0) noobs abbrev(10) // 변동계수
}


// --------------------------------------------------------------------------------
// 문제 3.b
// [Table 4] Coefficients' Estimates for Models (1) and (2)
//			 (1) Model (1): Run OLS for each segments (i.e., repeat 10 times)
//			 (2) Model (2): Run OLS for entire segments
// --------------------------------------------------------------------------------

frame pre2000_merge: {

	preserve 
		// 1. 로그 변수 생성
		gen log_IT = log(IT)
		gen log_GM = log(GM)
		gen log_CI = log(CI)
		gen log_SS = log(SS)
		

		// 2. 패널 선언
		egen firm_id = group(gvkey), label
		xtset firm_id fyear

		// 3. 모델 결과 저장용 파일 초기화
		tempfile model_results
		postfile results str50 model str50 industry_segment ///
			b_GM se_GM b_CI se_CI b_SS se_SS using `model_results', replace

		// 4. Model (1): 세그먼트별 xtreg (기업고정효과 + 연도더미 포함)
		levelsof industry_segment, local(segments)
		foreach seg in `segments' {
			quietly xtreg log_IT log_GM log_CI log_SS i.fyear if industry_segment == "`seg'", fe
			post results ("Model1") ("`seg'") ///
				(_b[log_GM]) (_se[log_GM]) ///
				(_b[log_CI]) (_se[log_CI]) ///
				(_b[log_SS]) (_se[log_SS])
		}

		// 5. Model (2): 전체 pooled xtreg (기업고정효과 + 연도더미 포함)
		quietly xtreg log_IT log_GM log_CI log_SS i.fyear, fe
		post results ("Model2") ("Pooled") ///
			(_b[log_GM]) (_se[log_GM]) ///
			(_b[log_CI]) (_se[log_CI]) ///
			(_b[log_SS]) (_se[log_SS])

		postclose results

		// 6. 결과 확인 및 저장
		use `model_results', clear
		rename (b_GM se_GM b_CI se_CI b_SS se_SS) ///
			   (GM_est SE_GM CI_est SE_CI SS_est SE_SS)
		save "model_table.dta", replace
	
	
	use model_table,clear
	// 출력 
	list industry_segment GM_est SE_GM CI_est SE_CI SS_est SE_SS, ///
		 noobs separator(0) abbrev(20) 
		 
	restore

}

frame post2000_merge: {

	preserve 
		// 1. 로그 변수 생성
		gen log_IT = log(IT)
		gen log_GM = log(GM)
		gen log_CI = log(CI)
		gen log_SS = log(SS)
		

		// 2. 패널 선언
		egen firm_id = group(gvkey), label
		xtset firm_id fyear

		// 3. 모델 결과 저장용 파일 초기화
		tempfile model_results
		postfile results str50 model str50 industry_segment ///
			b_GM se_GM b_CI se_CI b_SS se_SS using `model_results', replace

		// 4. Model (1): 세그먼트별 xtreg (기업고정효과 + 연도더미 포함)
		levelsof industry_segment, local(segments)
		foreach seg in `segments' {
			quietly xtreg log_IT log_GM log_CI log_SS i.fyear if industry_segment == "`seg'", fe
			post results ("Model1") ("`seg'") ///
				(_b[log_GM]) (_se[log_GM]) ///
				(_b[log_CI]) (_se[log_CI]) ///
				(_b[log_SS]) (_se[log_SS])
		}

		// 5. Model (2): 전체 pooled xtreg (기업고정효과 + 연도더미 포함)
		quietly xtreg log_IT log_GM log_CI log_SS i.fyear, fe
		post results ("Model2") ("Pooled") ///
			(_b[log_GM]) (_se[log_GM]) ///
			(_b[log_CI]) (_se[log_CI]) ///
			(_b[log_SS]) (_se[log_SS])

		postclose results

		// 6. 결과 확인 및 저장
		use `model_results', clear
		rename (b_GM se_GM b_CI se_CI b_SS se_SS) ///
			   (GM_est SE_GM CI_est SE_CI SS_est SE_SS)
		save "model_table.dta", replace
	
	
	use model_table,clear
	// 출력 
	list industry_segment GM_est SE_GM CI_est SE_CI SS_est SE_SS, ///
		 noobs separator(0) abbrev(20) 
		 
	restore

}

// -----------------------------------------------------------------------------------
// 문제 3.c : [Table 5] Estimates of Time-Specific Fixed Effects for Models (1) and (2)
// -----------------------------------------------------------------------------------

frame pre2000_merge: {
	
	preserve 
		// 1. 로그 변수 생성
		gen log_IT = log(IT)
		gen log_GM = log(GM)
		gen log_CI = log(CI)
		gen log_SS = log(SS)

		// 2. 1987~1999 더미변수 생성 (2000년은 기준년도로 제외)
		forvalues y = 1987/1999 {
			gen yr`y' = (fyear == `y')
		}

		// 3. 산업별 모델 추정 (Model 1)
		local model_list

		// 4. firm_id와 industry_id 생성
		egen firm_id = group(gvkey), label
		egen industry_id = group(industry_segment), label

		// 5. Model 1: 산업 고정효과 + 연도 고정효과
		levelsof industry_segment, local(segments)
		local segcount : word count `segments' // index 

		local i =0
		foreach seg of local segments {
			
			local ++i
			
			reghdfe log_IT log_GM log_CI log_SS yr1987-yr1999 if industry_segment == "`seg'", ///
				absorb(firm_id) vce(cluster firm_id)
			
			est store model_seg_`i'
			local model_list `model_list' model_seg_`i'
			
		}

		// 6. Model 2: 기업 고정효과 + 연도 고정효과
		reghdfe log_IT log_GM log_CI log_SS yr1987-yr1999, absorb(firm_id) vce(cluster firm_id)
		est store model_allFE

		
		// 7. 논문에서 언급한대로 산업별로 회귀를 10번돌리고 year fixed effects 계수의 평균을 구함 
		clear
		set obs 13
		gen year = 1987 + _n - 1
		gen model1_coef = .
		gen model1_stderr = .

		// Model 1 평균계수/표준오차 계산
		foreach i of numlist 1/10 {
			gen b`i' = .
			gen se`i' = .
		}

		// 10개 모델에서 yr1987~yr1999 계수와 표준오차 저장
		forvalues i = 1/10 {
			est restore model_seg_`i'
			matrix b = e(b)
			matrix V = e(V)
			forvalues y = 1987/1999 {
				local row = `y' - 1986
				replace b`i' = b[1, "yr`y'"] in `row'
				replace se`i' = sqrt(V["yr`y'", "yr`y'"]) in `row'
			}
		}

		// 평균 구하기
		forvalues y = 1987/1999 {
			local row = `y' - 1986
			replace model1_coef = (b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 + b10) / 10 in `row'
			replace model1_stderr = (se1 + se2 + se3 + se4 + se5 + se6 + se7 + se8 + se9 + se10) / 10 in `row'
		}

		// 8. 모델2 결과 가져오기
		est restore model_allFE
		matrix b = e(b)
		matrix V = e(V)

		gen model2_coef = .
		gen model2_stderr = .

		forvalues y = 1987/1999 {
			local row = `y' - 1986
			replace model2_coef = b[1, "yr`y'"] in `row'
			replace model2_stderr = sqrt(V["yr`y'", "yr`y'"]) in `row'
		}
		
		
		// 9. 모델1, 모델2의 결과를 표현 
		display "Table 5: Year Fixed Effects – Model 1 (Avg) vs Model 2 (Full)"
		list year model1_coef model1_stderr model2_coef model2_stderr, sep(0) noobs
	restore
}


frame post2000_merge: {
	
	preserve 
		// 1. 로그 변수 생성
		gen log_IT = log(IT)
		gen log_GM = log(GM)
		gen log_CI = log(CI)
		gen log_SS = log(SS)

		// 2. 1987~1999 더미변수 생성 (2000년은 기준년도로 제외)
		forvalues y = 2003/2014 {
			gen yr`y' = (fyear == `y')
		}

		// 3. 산업별 모델 추정 (Model 1)
		local model_list

		// 4. firm_id와 industry_id 생성
		egen firm_id = group(gvkey), label
		egen industry_id = group(industry_segment), label

		// 5. Model 1: 산업 고정효과 + 연도 고정효과
		levelsof industry_segment, local(segments)
		local segcount : word count `segments' // index 

		local i =0
		foreach seg of local segments {
			
			local ++i
			
			reghdfe log_IT log_GM log_CI log_SS yr2003-yr2014 if industry_segment == "`seg'", ///
				absorb(firm_id) vce(cluster firm_id)
			
			est store model_seg_`i'
			local model_list `model_list' model_seg_`i'
			
		}

		// 6. Model 2: 기업 고정효과 + 연도 고정효과
		reghdfe log_IT log_GM log_CI log_SS yr2003-yr2014, absorb(firm_id) vce(cluster firm_id)
		est store model_allFE

		
		// 7. 논문에서 언급한대로 산업별로 회귀를 10번돌리고 year fixed effects 계수의 평균을 구함 
		clear
		set obs 13
		gen year = 2003 + _n - 1
		gen model1_coef = .
		gen model1_stderr = .

		// Model 1 평균계수/표준오차 계산
		foreach i of numlist 1/10 {
			gen b`i' = .
			gen se`i' = .
		}

		// 10개 모델에서 yr1987~yr1999 계수와 표준오차 저장
		forvalues i = 1/10 {
			est restore model_seg_`i'
			matrix b = e(b)
			matrix V = e(V)
			forvalues y = 2003/2014 {
				local row = `y' - 2002
				replace b`i' = b[1, "yr`y'"] in `row'
				replace se`i' = sqrt(V["yr`y'", "yr`y'"]) in `row'
			}
		}

		// 평균 구하기
		forvalues y = 2003/2014 {
			local row = `y' - 2002
			replace model1_coef = (b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 + b10) / 10 in `row'
			replace model1_stderr = (se1 + se2 + se3 + se4 + se5 + se6 + se7 + se8 + se9 + se10) / 10 in `row'
		}

		// 8. 모델2 결과 가져오기
		est restore model_allFE
		matrix b = e(b)
		matrix V = e(V)

		gen model2_coef = .
		gen model2_stderr = .

		forvalues y = 2003/2014 {
			local row = `y' - 2002
			replace model2_coef = b[1, "yr`y'"] in `row'
			replace model2_stderr = sqrt(V["yr`y'", "yr`y'"]) in `row'
		}
		
		
		// 9. 모델1, 모델2의 결과를 표현 
		display "Table 5: Year Fixed Effects – Model 1 (Avg) vs Model 2 (Full)"
		list year model1_coef model1_stderr model2_coef model2_stderr, sep(0) noobs
	restore
}
		
// -----------------------------------------------------------------------------------
// 문제 3.d : [Figure 2] Plot of Time-Specific Fixed Effects for Model (2) [5 points]
// -----------------------------------------------------------------------------------


frame pre2000_merge: {
	preserve 
		// 1. 로그 변수 생성
		gen log_IT = log(IT)
		gen log_GM = log(GM)
		gen log_CI = log(CI)
		gen log_SS = log(SS)


		// 2. 1987~1999 더미변수 생성 (2000년은 기준년도로 제외)
		forvalues y = 1987/1999 {
			gen yr`y' = (fyear == `y')
		}

		// 3. firm_id와 industry_id 생성
		egen firm_id = group(gvkey), label

		// 4. Model 2: 기업 고정효과 + 연도 고정효과
		reghdfe log_IT log_GM log_CI log_SS yr1987-yr1999, absorb(firm_id) vce(cluster firm_id)
		est store pre_model_allFE

		est restore pre_model_allFE

		// 회귀계수와 분산행렬 불러오기
		matrix b = e(b)
		matrix V = e(V)

		// 1987~1999만 추출
		clear
		set obs 13
		gen year = 1987 + _n - 1
		gen coef = .
		gen se = .

		forvalues y = 1987/1999 {
			local row = `y' - 1986
			replace coef = b[1, "yr`y'"] in `row'
			replace se = sqrt(V["yr`y'","yr`y'"]) in `row'
		}
				
		gen ub = coef + 1.96 * se
		gen lb = coef - 1.96 * se


		twoway (rcap ub lb year if year>=1987 & year<=1999, lcolor(black)) ///
		   (scatter coef year if year>=1987 & year<=1999, mcolor(black) msymbol(diamond)), ///
		yline(0, lpattern(solid) lcolor(black)) ///
		xlabel(1986(2)2000, labsize(small)) ///
		ylabel(-0.04(0.04)0.16, grid labsize(small)) ///
		xtitle("Time (in years)", size(medlarge)) ///
		ytitle("c(t)", size(medlarge)) ///
		title("Figure 2: Plot of Time-Specific Fixed Effects ct for Model (2)", size(medium)) ///
		legend(off)
	restore	
}


frame post2000_merge: {
	preserve 

		// 1. 로그 변수 생성
		gen log_IT = log(IT)
		gen log_GM = log(GM)
		gen log_CI = log(CI)
		gen log_SS = log(SS)


		// 2. 2002~2014 더미변수 생성 (2015 기준년도로 제외)
		forvalues y = 2003/2014 {
			gen yr`y' = (fyear == `y')
		}

		// 3. firm_id와 industry_id 생성
		egen firm_id = group(gvkey), label

		// 4. Model 2: 기업 고정효과 + 연도 고정효과
		reghdfe log_IT log_GM log_CI log_SS yr2003-yr2014, absorb(firm_id) vce(cluster firm_id)
		est store post_model_allFE

		est restore post_model_allFE

		// 회귀계수와 분산행렬 불러오기
		matrix b = e(b)
		matrix V = e(V)

		// 1987~1999만 추출
		clear
		set obs 13
		gen year = 2003 + _n - 1
		gen coef = .
		gen se = .

		forvalues y = 2003/2014 {
			local row = `y' - 2002
			replace coef = b[1, "yr`y'"] in `row'
			replace se = sqrt(V["yr`y'","yr`y'"]) in `row'
		}
				
		gen ub = coef + 1.96 * se
		gen lb = coef - 1.96 * se


		twoway (rcap ub lb year if year>=2003 & year<=2014, lcolor(black)) ///
		   (scatter coef year if year>=2003 & year<=2014, mcolor(black) msymbol(diamond)), ///
		yline(0, lpattern(solid) lcolor(black)) ///
		xlabel(2002(2)2014, labsize(small)) ///
		ylabel(-0.04(0.04)0.16, grid labsize(small)) ///
		xtitle("Time (in years)", size(medlarge)) ///
		ytitle("c(t)", size(medlarge)) ///
		title("Figure 2: Plot of Time-Specific Fixed Effects ct for Model (2)", size(medium)) ///
		legend(off)

	restore	
}

// -----------------------------------------------------------------------------------
// 문제 3.e : [Table 6] Time Trends in IT, CI, and GM Estimated Using Equation (5)
// -----------------------------------------------------------------------------------

frame pre2000_merge: {
	preserve 
		// [1] 전처리
		gen t = fyear
		gen log_IT = log(IT)
		gen log_CI = log(CI)
		gen log_GM = log(GM)

		// [2] 결과 저장용 frame 생성 및 초기화
		frame create pre_result_frame
		frame change pre_result_frame

		set obs 6
		gen str10 varname = ""
		gen coef = .
		gen se   = .
		gen tval = .
		gen pval = .
		gen obs  = .

		// [3] 데이터 frame으로 돌아가서 회귀 실행
		frame change pre2000_merge

		local vars IT log_IT CI log_CI GM log_GM
		local i = 1
		foreach v of local vars {
			reghdfe `v' t, absorb(gvkey) vce(cluster gvkey)

			// 결과 저장 frame에서 저장
			frame pre_result_frame {
				replace varname = "`v'" in `i'
				replace coef    = _b[t] in `i'
				replace se      = _se[t] in `i'
				replace tval    = _b[t]/_se[t] in `i'
				replace pval    = 2*ttail(e(df_r), abs(_b[t]/_se[t])) in `i'
				replace obs     = e(N) in `i'

				// 디버깅용 로그
				display "====== row `i' updated ======"
				list varname coef se tval pval obs in `i'
			}

			local ++i
		}

		// [4] 최종 출력
		frame pre_result_frame {
			list varname coef se tval pval obs, sep(0) noobs
		}
	restore	
}


frame post2000_merge: {
	preserve 
		// [1] 전처리
		gen t = fyear
		gen log_IT = log(IT)
		gen log_CI = log(CI)
		gen log_GM = log(GM)

		// [2] 결과 저장용 frame 생성 및 초기화
		frame create post_result_frame
		frame change post_result_frame

		set obs 6
		gen str10 varname = ""
		gen coef = .
		gen se   = .
		gen tval = .
		gen pval = .
		gen obs  = .

		// [3] 데이터 frame으로 돌아가서 회귀 실행
		frame change post2000_merge

		local vars IT log_IT CI log_CI GM log_GM
		local i = 1
		foreach v of local vars {
			reghdfe `v' t, absorb(gvkey) vce(cluster gvkey)

			// 결과 저장 frame에서 저장
			frame post_result_frame {
				replace varname = "`v'" in `i'
				replace coef    = _b[t] in `i'
				replace se      = _se[t] in `i'
				replace tval    = _b[t]/_se[t] in `i'
				replace pval    = 2*ttail(e(df_r), abs(_b[t]/_se[t])) in `i'
				replace obs     = e(N) in `i'

				// 디버깅용 로그
				display "====== row `i' updated ======"
				list varname coef se tval pval obs in `i'
			}

			local ++i
		}

		// [4] 최종 출력
		frame post_result_frame {
			list varname coef se tval pval obs, sep(0) noobs
		}
	restore	
}
