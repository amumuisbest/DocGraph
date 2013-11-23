/* We want to map RxCUIs to ATC codes s*/


use RxNorm;

select * from RxNorm.RxnConso where sab='ATC' and (TTY = 'RXN_PT' or TTY = 'RXN_IN') order by code;
/* 661 */

select * from RxNorm.RxnConso where sab='ATC' and (TTY = 'PT') order by str;
/* 1255 */

select * from RxNorm.RxnConso where sab='ATC' and (TTY = 'PT' or TTY = 'IN') order by code;
/* 5771 */

select * from RxNorm.RxnConso where sab='ATC' and (TTY = 'IN') order by code;
/* 4516 */

select distinct RXCUI from RxNorm.RxnConso where sab='ATC' and (TTY = 'IN') order by code;
/* 3877 */

select * from RxNorm.RxnConso r1 
  join RxNorm.RxnConso r2 on 
r2.RXCUI = r1.RXCUI and (r2.sab in ('RXNORM'))
where r1.sab='ATC' and r1.TTY = 'IN' and r2.TTY = 'IN'
order by r1.code;
/* 2742 */

select distinct r1.RXCUI from RxNorm.RxnConso r1 
  join RxNorm.RxnConso r2 on 
r2.RXCUI = r1.RXCUI and (r2.sab in ('RXNORM'))
where r1.sab='ATC' and r1.TTY = 'IN' and r2.TTY = 'IN'
order by r1.code;

/* 2195 */

/* Which ATC codes are not mapped */

select  distinct r1.str, r1.rxcui from RxNorm.RxnConso r1 
  left outer join RxNorm.RxnConso r2 on 
  r2.RXCUI = r1.RXCUI and r2.sab in ('RXNORM') and r2.TTY = 'IN'
  where r1.sab='ATC' and r1.TTY = 'IN'  and r2.RXCUI is null
  order by r1.str;

/* 1684 */

select  distinct r1.rxcui from RxNorm.RxnConso r1 
  left outer join RxNorm.RxnConso r2 on 
  r2.RXCUI = r1.RXCUI and r2.sab in ('RXNORM') and r2.TTY = 'IN'
  where r1.sab='ATC' and r1.TTY = 'IN'  and r2.RXCUI is null
  order by r1.str;

/* 1682 */

/* 1682 + 2195 = 3877 */

/* Count which ingredients we will need to disambiguate */

select count(*), r1.str from RxNorm.RxnConso r1 
  join RxNorm.RxnConso r2 on 
  r2.RXCUI = r1.RXCUI and (r2.sab in ('RXNORM'))
  where r1.sab='ATC' and r1.TTY = 'IN' and r2.TTY = 'IN'
  group by r1.str having count(*) > 1 order by count(*) desc;

/* 322 */

create index idx_rxn_code on RxNorm.RxnConso(code);
create index idx_rel_rc1 on RxNorm.RxnRel(rxcui1);
create index idx_rel_rc2 on RxNorm.RxnRel(rxcui2);
create index idx_rel_ra1 on RxNorm.RxnRel(rxaui1);
create index idx_rel_ra2 on RxNorm.RxnRel(rxaui2);
create index idx_rel_rela on RxNorm.RxnRel(rela);
create index idx_rel_rela on RxNorm.RxnCONSO(rela);

select * from RxnREL where sab = 'ATC';
/* 11514 */

select distinct RELA from RxnREL where sab = 'RXNORM';

/*
RELA

consists_of
constitutes
contained_in
contains
dose_form_of
doseformgroup_of
form_of
has_dose_form
has_doseformgroup
has_form
has_ingredient
has_ingredients
has_part
has_precise_ingredient
has_quantified_form
has_tradename
included_in
includes
ingredient_of
ingredients_of
inverse_isa
isa
part_of
precise_ingredient_of
quantified_form_of
reformulated_to
reformulation_of
tradename_of

*/

select distinct ATN from RxnSat where sab = 'RXNORM';

select distinct * from RxnSat where sab = 'RXNORM' and ATN like 'RXTERM_FORM';


select * from RxnSat where sab = 'ATC';
select * from RxnREL where sab = 'RXNORM' and rela = 'ingredient_of';

select tt.rxcui, tt.STR, tt.CODE, r5.str, r5.rxcui from RxnREL  rr join (
    select distinct r3.rxcui, r3.str, r3.code from RxnConso r3 join 
      (select r1.str from RxNorm.RxnConso r1 
        join RxNorm.RxnConso r2 on 
        r2.RXCUI = r1.RXCUI and (r2.sab in ('RXNORM'))
        where r1.sab='ATC' and r1.TTY = 'IN' and r2.TTY = 'IN'
        group by r1.str having count(*) > 1) t on t.str = r3.str 
      and r3.TTY = 'IN' and r3.SAB = 'ATC') tt 
    on rr.SAB = 'RXNORM' and rr.RELA = 'ingredient_of' 
    and rr.RXCUI2 = tt.rxcui
    join RxnConso r5 on r5.rxcui = rr.rxcui1 and r5.sab = 'RXNORM' and TTY = 'SCDF'
    order by tt.str, tt.code, r5.str;
    
    
    
/* Create the ATC Table */

drop table if exists rxnorm_prescribe.atc_ingredients;
    
create table rxnorm_prescribe.atc_ingredients as
  select *, concat('|', atc5, '|', '|', atc4, '|', '|', atc3, '|', '|', atc2, '|', '|', atc1, '|') as atc_code_concat,
    concat('|', ATC5_Name, '|','|', ATC4_Name, '|','|', ATC3_Name, '|','|', ATC2_Name, '|','|', ATC1_Name, '|') as atc_name_concat 
  from (
   select t.*, r4.STR as ATC4_Name, r3.STR as ATC3_Name, r2.STR as ATC2_Name,
     r1.STR as ATC1_Name
    from rxnorm.rxnconso r4 join        
    (select r1.rxcui, r1.CODE as ATC5,
      left(CODE,5) as ATC4,
      left(CODE,4) as ATC3,
      left(CODE,3) as ATC2,
      left(CODE,1) as ATC1,
       r1.STR as ATC5_Name
        from rxnorm.RxnConso r1 where r1.SAB = 'ATC' and r1.TTY = 'IN') t
     on t.ATC4 = r4.Code and r4.SAB = 'ATC' and r4.tty = 'PT'
     join rxnorm.rxnconso r3 on t.ATC3 = r3.Code and r3.SAB = 'ATC' and r3.tty = 'PT'
     join rxnorm.rxnconso r2 on t.ATC2 = r2.Code and r2.SAB = 'ATC' and r2.tty = 'PT'
     join rxnorm.rxnconso r1 on t.ATC1 = r1.Code and r1.SAB = 'ATC' and r1.tty = 'PT') tt
     order by tt.ATC5;
   
  /* 4516 */ 
   
select distinct atc2, atc2_Name from rxnorm_prescribe_atc_ingredients;
/* 90 */  
  
select distinct atc3, atc3_Name from atc_ingredients;
/* 243 */
   
select distinct atc4, atc4_Name from atc_ingredients;   
/* 782 */

create index idx_dd_scd_rxcui on rxnorm_prescribe.drug_details(scd_rxcui);
  
select distinct t.indicator, t.counter, r2.str as dosage_form, ai.*, r2.rxcui as rxcui_dosage from atc_ingredients ai join 
   rxnrel rr1 on ai.rxcui = rr1.RXCUI2 and rela = 'ingredient_of' and rr1.SAB = 'RXNORM'
   join RxnConso r1 on r1.rxcui = rr1.RXCUI1 and r1.TTY = 'SCDF'
   join rxnrel rr2 on rr2.RXCUI2 = r1.RXCUI and rr2.rela = 'has_dose_form' and rr2.SAB = 'RXNORM' 
   join RxnConso r2 on r2.rxcui = rr2.RXCUI1 and r2.TTY = 'FN'
   left outer join 
    (select zz.atc5_name, 1 as indicator, count(*) as counter 
      from atc_ingredients zz group by zz.atc5_name having count(*) > 1) t
   on t.atc5_name = ai.atc5_name
   order by ai.atc5_name, ai.atc5, r2.str
    ;

    
/*    
select * from rxnorm_prescribe.drug_details dd join
  (select distinct r2.rxcui as df_rxcui, r2.rxaui as df_rxaui, r2.str as dose_form, 
    r1.rxcui as dfg_rxcui, r1.rxaui as dfg_rxaui, r1.str as dose_form_group  
  from rxnorm.rxnconso r1 join rxnorm.rxnrel rr1 on r1.rxcui = rr1.RXCUI1
    join rxnorm.rxnconso r2 on r2.rxcui = rr1.RXCUI2 where r1.SAB = 'RXNORM' and r2.SAB = 'RXNORM'
    and r1.TTY = 'DFG' and r2.TTY='DF') t on t.df_rxaui = dd.dose_form_rxaui;
*/

drop table rxnorm_prescribe.atc_ingredient_link_to_in_rxcui1;

create table rxnorm_prescribe.atc_ingredient_link_to_in_rxcui1    
 select distinct ai.*, dd.dose_form, dd.rxn_human_drug, dd.rxterm_form, dd.synthetic_dfg_rxcui,
  dd.synthetic_dfg_rxaui, dd.synthetic_dose_form_group
    from rxnorm_prescribe.drug_details dd
  join  rxnorm_prescribe.relation_between_ingredient_clinical_drug rcd on dd.scd_rxcui = rcd.scd_rxcui
  join rxnorm_prescribe.ingredient_details id on id.in_rxaui = rcd.in_rxaui
  join rxnorm_prescribe.atc_ingredients ai on ai.rxcui = id.in_rxcui
  order by ATC5_Name, ATC5;


drop table if exists rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2;

create table rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2  
  select t.* from (
    select ail.*, t.counter from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui1 ail join (  
      select rxcui, ATC5_Name, count(distinct atc5) as counter from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui1
      group by ATC5_Name) t where t.rxcui = ail.rxcui) t order by counter desc, atc5_name, atc5;
    ;

select count(*) as counter, 
  dose_form, rxterm_form ,atc1_name from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where counter = 1 and atc1 = 'A'
  group by dose_form, rxterm_form ,atc1_name
  order by count(*) desc;
  ;
/* 46 */  
  
/* 
 ('Ophthalmic Gel', 'Topical Solution', 'Otic Solution', 'Topical Lotion', 'Topical Foam', 'Vaginal Cream', 'Transdermal Patch','Irrigation Solution','TOPICAL SPRAY','Topical Gel','Topical Ointment','Topical Cream','Ophthalmic Solution')
*/

drop table if exists rxnorm_prescribe.atc_ingredient_link_to_in_rxcui3;

create table rxnorm_prescribe.atc_ingredient_link_to_in_rxcui3   
  select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2;
  
delete from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui3 where rxn_human_drug is NULL;
 
 /*Enemas and rectal foams for treatment of e.g. ulcerative colitis are classified here. Oral budesonide for treatment of morbus Crohn is also classified here. */

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui3;

drop table if exists rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated;

create table rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated as 
  select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form,
    1 as step
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc4 = 'A07EA' and synthetic_dose_form_group
      like 'Rectal%';


/* 

New search    Hide text from Guidelines
A ALIMENTARY TRACT AND METABOLISM
A01 STOMATOLOGICAL PREPARATIONS

A01A STOMATOLOGICAL PREPARATIONS

This group comprises agents for treatment of conditions of mouth and teeth. It is difficult to differentiate between preparations for use in the mouth and preparations for use in the throat. Preparations mainly used in gingivitis, stomatitis etc. should be classified in this group.

Preparations for the treatment of throat infections, (lozenges for common cold conditions) are classified in R02 - Throat preparations.

Preparations containing local anesthetics, see N01B - Anesthetics, local, and R02AD - Anesthetics, local */

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
    select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 2 as step 
     from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'A01A' and dose_form in ('Mouthwash', 'Oral Gel', 'Oral Paste', 'Oral Foam', 'Toothpaste');

/*
This group comprises plain antacid drugs, antacids in combination with antiflatulents and antacids in combination with other drugs.

Antacids in combination with liquorice root or linseed are classified in this group.


Plain antiflatulents, see A03AX - Other drugs for functional gastrointestinal disorders.
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
  select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 3 as step 
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A02' and synthetic_dose_form_group not like 'Injectable Product%'
    and synthetic_dose_form_group like 'Oral Product%'; 
 /* 
Unsure about
2541	A02BA01	A02BA	A02B	A02	A	cimetidine	H2-receptor antagonists	DRUGS FOR PEPTIC ULCER AND GASTRO-OESOPHAGEAL REFLUX DISEASE (GORD)	DRUGS FOR ACID RELATED DISORDERS	ALIMENTARY TRACT AND METABOLISM	Injectable Solution	US	Sol	1
283742	A02BC05	A02BC	A02B	A02	A	esomeprazole	Proton pump inhibitors	DRUGS FOR PEPTIC ULCER AND GASTRO-OESOPHAGEAL REFLUX DISEASE (GORD)	DRUGS FOR ACID RELATED DISORDERS	ALIMENTARY TRACT AND METABOLISM	Injectable Solution	US	Sol	1
4278	A02BA03	A02BA	A02B	A02	A	famotidine	H2-receptor antagonists	DRUGS FOR PEPTIC ULCER AND GASTRO-OESOPHAGEAL REFLUX DISEASE (GORD)	DRUGS FOR ACID RELATED DISORDERS	ALIMENTARY TRACT AND METABOLISM	Injectable Solution	US	Sol	1
40790	A02BC02	A02BC	A02B	A02	A	pantoprazole	Proton pump inhibitors	DRUGS FOR PEPTIC ULCER AND GASTRO-OESOPHAGEAL REFLUX DISEASE (GORD)	DRUGS FOR ACID RELATED DISORDERS	ALIMENTARY TRACT AND METABOLISM	Injectable Solution	US	Sol	1
9143	A02BA02	A02BA	A02B	A02	A	ranitidine	H2-receptor antagonists	DRUGS FOR PEPTIC ULCER AND GASTRO-OESOPHAGEAL REFLUX DISEASE (GORD)	DRUGS FOR ACID RELATED DISORDERS	ALIMENTARY TRACT AND METABOLISM	Injectable Solution	US	Sol	1
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 4 as step from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A03' and
  synthetic_dose_form_group like 'Oral Product%';


insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 5 as step 
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A04' 
  and (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable%' or synthetic_dose_form_group like '%Topical%');

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A05' and dose_form not in ('Prefilled Applicator','Mouthwash', 'Oral Gel', 'Oral Paste', 'Oral Foam', 'Toothpaste', 'Chewing Gum', 'Lozenge', 'Irrigation Solution','Topical Ointment', 'Ophthalmic Solution');
/* no records */

/* DRUGS FOR CONSTIPATION */
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 6 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A06' 
  and (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Rectal Product%'
);

/*ANTIDIARRHEALS, INTESTINAL ANTIINFLAMMATORY/ANTIINFECTIVE AGENTS*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 7 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A07' and (synthetic_dose_form_group like 'Oral Product%');
  

/* Antiobesity */

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 8 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A08' and (synthetic_dose_form_group like 'Oral Product%');

/* Enzymes */
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 9 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A09' and (synthetic_dose_form_group like 'Oral Product%');

/* Diabetes drugs */
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 10 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A10' and 
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');

/* Vitamins */
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 11 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A11' and (synthetic_dose_form_group like 'Oral Product%');
;

/* MINERAL SUPPLEMENTS */
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 12 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A12' and (synthetic_dose_form_group like 'Oral Product%');


/* A13 TONICS*/
select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A13';

/* A14 Anabolic Steroids*/
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 13 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A14' and (synthetic_dose_form_group like 'Oral Product%');

/* Appetite stimulators */

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'A15';



/*B01 ANTITHROMBOTIC AGENTS*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 14 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'B01' and 
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');


/* epinephrine */
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 15 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'B02' and 
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');
  
  
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 15 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'B03' and 
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');


select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 15 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'B04';

/*
B05A BLOOD AND RELATED PRODUCTS
B05B I.V. SOLUTIONS

This group comprises i.v. solutions used in parenteral administration of fluids, electrolytes and nutrients. Agents administered as i.v. solutions or additives, see the respective therapeutic groups. I.v. solution additives, see B05X.

B05C IRRIGATING SOLUTIONS

In this group products used for bladder irrigation, surgical irrigation, incl. instruments etc. are classified. See also V07AB - Solvents and diluting agents, incl. irrigating solutions.

Combined preparations are classified by using 5th level - 10. Only plain preparations are classified at the other 5th levels.

B05D PERITONEAL DIALYTICS
B05X I.V. SOLUTION ADDITIVES

I.v. solution additives are concentrated preparations containing substances used for correcting fluid and electrolyte balance and nutritional status. Drugs administered as i.v. solutions or additives, see the respective groups.

B05Z HEMODIALYTICS AND HEMOFILTRATES
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 16 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'B05A' and 
  (synthetic_dose_form_group like 'Injectable Product%');
  
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 17 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'B05B' and 
  (synthetic_dose_form_group like 'Injectable Product%');

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 18 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'B05C' and 
  (synthetic_dose_form_group like 'Irrigation Product%');



/*
C CARDIOVASCULAR SYSTEM

C01 CARDIAC THERAPY

*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 19 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C01' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');

/*
C02 ANTIHYPERTENSIVES

See also C03 - Diuretics, C07 - Beta blocking agents, C08 - Calcium channel blockers and C09 - Agents acting on the renin-angiotensin system.

Antihypertensives are mainly classified at 3rd levels according to the mechanism of action. Most headings are self-explanatory:

C02A Antiadrenergic agents, centrally acting
C02B Antiadrenergic agents, ganglion-blocking
C02C Antiadrenergic agents, peripherally acting
C02D Arteriolar smooth muscle, agents acting on
C02K Other antihypertensives
C02L Antihypertensives and diuretics in combination
C02N Combinations of antihypertensives in ATC gr. C02

The oral DDDs are based on the average doses needed to reduce the blood pressure to a normal level in patients with mild-moderate hypertension.

Parenteral DDDs are based on dosages used for the treatment of hypertensive crises and are based on the content of the active ingredient pr. vial (ampoule).
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 20 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C02' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');


/* C03 DIURETICS */
/*
This group comprises diuretics, plain and in combination with potassium or other agents. Vasopressin antagonists are also included in this group. Potassium-sparing agents are classified in C03D and C03E.

Combinations with digitalis glycosides, see C01AA.

Combinations with antihypertensives, see C02L - Antihypertensives and diuretics in combination.

Combinations with beta blocking agents, see C07B - C07D.

Combinations with calcium channel blockers, see C08.

Combinations with agents acting on the renin angiotensin system, see C09B and C09D.

The DDDs for diuretics are based on monotherapy. Most diuretics are used both for the treatment of edema and hypertension in similar doses and the DDDs are therefore based on both indications.

The DDDs for combinations correspond to the DDD for the diuretic component, except for ATC group C03E, see comments under this level.
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 21 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C03' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');


/*
C04 PERIPHERAL VASODILATORS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 22 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C04' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');



/*
C05 VASOPROTECTIVES

No DDDs are established in this group, since most of the drugs in this group are for topical use.
*/


insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 23 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C05' and
  (synthetic_dose_form_group like  'Rectal Product%');

/*
C07 BETA BLOCKING AGENTS
*/


insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 24 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C07' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');


/*
C08 CALCIUM CHANNEL BLOCKERS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 25 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C08' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');

/*
The calcium channel blockers are classified according to selectivity of calcium channel activity and direct cardiac effects. The ATC 4th levels are subdivided according to chemical structure.

Combinations with ergot alkaloids (C04AE) are classified in this group by using the 50-series.

Combinations with diuretics are classified in C08G.

Combinations with ACE inhibitors are classified in C09BB.

Combinations with beta blocking agents are classified in C07F.

The DDDs for calcium channel blockers are based on the treatment of mild-moderate hypertension, although some are used for other indications (e.g. angina pectoris).

The DDDs for oral and parenteral preparations are equal and are based on the oral dose, since oral preparations represent the major fraction of the total consumption.

C09 AGENTS ACTING ON THE RENIN-ANGIOTENSIN SYSTEM

The DDDs are based on the treatment of mild-moderate hypertension.

See comments to C02L concerning the principles for assignment of DDDs for combined preparations.
*/

/*
C10 LIPID MODIFYING AGENTS

The DDDs are based on the treatment of hypercholesterolemia.
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 26 as step  
from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'C10' and
  (synthetic_dose_form_group like 'Oral Product%' or synthetic_dose_form_group like 'Injectable Product%');

/*
D DERMATOLOGICALS

Most of the drugs in this group are preparations for topical use. Some few preparations for systemic use with clear dermatological applications, e.g. griseofulvin (antimycotic), retinoids (for treatment of acne) and psoralens and retinoids (for treatment of psoriasis) are classified in this group.

Only oral preparations in ATC group D are given DDDs. Most products in this group are for topical use, and no DDDs are assigned because the amount given per day can vary very much according to the intensity and distribution of the disease. Consumption figures for these dermatological preparations can be expressed in grams of preparations regardless of strength.


D01 ANTIFUNGALS FOR DERMATOLOGICAL USE

*/
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
    select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 27 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'D01A' and
      (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%');


insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
   select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 28 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'D01B' and
    (synthetic_dose_form_group like 'Oral Product%');
/*

This group comprises preparations for topical and systemic treatment of dermatological mycoses. Preparations with systemic antimycotic effect, see also J02A - Antimycotics for systemic use.

Topical preparations used especially in gynecological infections are classified in G01A - Antiinfectives and antiseptics, excl. combinations with corticosteroids or G01B - Antiinfectives/antiseptics in combination with corticosteroids. Preparations for local treatment of fungal infections in the mouth, see A01AB - Antiinfectives and antiseptics for local oral treatment.
*/
/*
D02 EMOLLIENTS AND PROTECTIVES

*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
   select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 29 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D02' and
          (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%' or synthetic_dose_form_group like 'Paste Product%' or 
          synthetic_dose_form_group like 'Prefilled Applicator Product%');


/*
D03 PREPARATIONS FOR TREATMENT OF WOUNDS AND ULCERS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 30 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D03' and
                   (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%' or synthetic_dose_form_group like 'Paste Product%' or 
          synthetic_dose_form_group like 'Prefilled Applicator Product%');

/*
Topical preparations used in the treatment of wounds and ulcers, e.g. leg ulcers, are classified in this group. Protective ointments are classified in D02A - Emollients and protectives.

See also
D06 - Antibiotic and chemotherapeutics for dermatological use.
D08 - Antiseptics and disinfectants.
D09 - Medicated dressings.
*/

/*
D04 ANTIPRURITICS, INCL. ANTIHISTAMINES, ANESTHETICS, ETC. */

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 31 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D04' and
                    (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%' or synthetic_dose_form_group like 'Paste Product%' or 
          synthetic_dose_form_group like 'Prefilled Applicator Product%');
;

/*
D05 ANTIPSORIATICS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 32 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D05' and
                    (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%' or synthetic_dose_form_group like 'Paste Product%' or 
          synthetic_dose_form_group like 'Prefilled Applicator Product%');


/*
D06 ANTIBIOTICS AND CHEMOTHERAPEUTICS FOR DERMATOLOGICAL USE
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 33 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D06' and
                    (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%' or synthetic_dose_form_group like 'Paste Product%' or 
          synthetic_dose_form_group like 'Prefilled Applicator Product%');

/*
This group comprises products for topical use in skin infections etc.
*/
/*
D07 CORTICOSTEROIDS, DERMATOLOGICAL PREPARATIONS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 34 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D07' and
                    (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%' );

/*
As a main rule, all topical corticosteroid preparations should be classified in this group. There are, however, some few exceptions:

Combinations of corticosteroids and antiinfectives for gynaecological use, see G01B.

Corticosteroids for local oral treatment, see A01AC.

Anti-acne preparations, see D10A.

Antihemorrhoidals with corticosteroids, see C05AA.

Corticosteroids for ophthalmological or otological use, see S - Sensory organs.
*/
/*
D08 ANTISEPTICS AND DISINFECTANTS
*/
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 35 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D08' and
                    (synthetic_dose_form_group like 'Topical Product%' or synthetic_dose_form_group like 'Shampoo Product%'
                    or synthetic_dose_form_group like 'Soap Product%'
                    );

/*
D09 MEDICATED DRESSINGS
*/
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 36 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'D09' and
                    (synthetic_dose_form_group like '%Medicated Pad%');
/*
D10 ANTI-ACNE PREPARATIONS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
    select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form,37 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'D10A' and
      (synthetic_dose_form_group like 'Topical Product%'
      or synthetic_dose_form_group like 'Prefilled Applicator%');


insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
   select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 38 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'D10B' and
    (synthetic_dose_form_group like 'Oral Product%');


/*

G GENITO URINARY SYSTEM AND SEX HORMONES
*/
/*
G01 GYNECOLOGICAL ANTIINFECTIVES AND ANTISEPTICS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 39 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'G01' and
                    (synthetic_dose_form_group like '%Vaginal%');


/*
This group comprises gynecological antiinfectives and antiseptics mainly for local use. See also:

J - Antiinfectives for systemic use
D06 - Antibiotics and chemotherapeutics for dermatological use
P01AB - Nitroimidazole derivatives

The DDDs are based on the treatment of vaginal infections.
*/
/*
G02 OTHER GYNECOLOGICALS
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 40 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'G02A';
    
    
insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 41 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'G02B';
    

/*
Analgesics used in dysmenorrhea, see N02B - Other analgesics and antipyretics and M01A - Antiinflammatory and antirheumatic products, non-steroids.
*/
/*
G03 SEX HORMONES AND MODULATORS OF THE GENITAL SYSTEM
*/

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 42 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'G03' ;


/*

Other hormones, see H - Systemic hormonal preparations, excl. sex hormones and insulins.

Sex hormones used only in the treatment of cancer (often selected strengths) are classified in L - Antineoplastic and immunomodulating agents.

The DDDs of many of the hormone preparations may vary considerably with the route of administration due to substantial differences in bioavailability. The DDDs of depot preparations are calculated as the dose divided by the dosing interval.
*/
/*
G04 UROLOGICALS
*/


 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 42 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc2 = 'G04';

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 43 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc4 = 'G04BA' 
    and (synthetic_dose_form_group like 'Oral Product%');
    ;


insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 44 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc4 = 'G04BD' ;



insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 45 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc4 = 'G04BE' and synthetic_dose_form_group not like 'Injectable Product%' ;
    
    

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 46 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc4 = 'G04BX' and synthetic_dose_form_group not like 'Injectable Product%'
      and (synthetic_dose_form_group like 'Oral Product%');
    ;    

insert into rxnorm_prescribe.atc_ingredient_link_to_rxcui_curated (rxcui, atc5_name, atc_code_concat, atc_name_concat, 
  synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, step)
 select rxcui, atc5_name, atc_code_concat, atc_name_concat, synthetic_dose_form_group, synthetic_dfg_rxaui, dose_form, 47 as step  
    from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc3 = 'G04C';


/*
Antiseptic and antiinfective preparations for systemic use specifically used in urinary tract infections, see J01.

Antiinfectives for systemic use, see group J.

Gynecological antiinfectives and antiseptics, see G01.*/


/*

H SYSTEMIC HORMONAL PREPARATIONS, EXCL. SEX HORMONES AND INSULINS

This group comprises all hormonal preparations for systemic use, except:

- Insulins, see A10.
- Anabolic steroids, see A14.
- Catecholamines, see C01C and R03C.
- Sex hormones, see G03.
- Sex hormones used in treatment of neoplastic diseases, see L02.

The DDDs are generally based on the treatment or diagnosis of endocrine disorders.


H01 PITUITARY AND HYPOTHALAMIC HORMONES AND ANALOGUES
H02 CORTICOSTEROIDS FOR SYSTEMIC USE

As a main rule, systemic corticosteroids should be classified in this group. There is, however, one exception: M01BA - Antiinflam-matory/antirheumatic agents in combination with corticosteroids.

Corticosteroids for local oral treatment, see A01AC.

Enemas and rectal foams for local treatment of e.g. ulcerative colitis, see A07E.

Corticosteroids for topical use, see D07.

Combined corticosteroid preparations for local treatment of acne, see D10AA.

Corticosteroids in combination with antiinfectives/antiseptics for local treatment of gynecological infections, see G01B.

Corticosteroids for nasal use, see R01AD.
Corticosteroids for inhalation, see R03BA.

Corticosteroids, eye/ear preparations, see S.

H03 THYROID THERAPY
H04 PANCREATIC HORMONES
H05 CALCIUM HOMEOSTASIS

Drugs acting on calcium homeostasis are classified in this group.

Vitamin-D preparations, see A11CC.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'H';

/*
J ANTIINFECTIVES FOR SYSTEMIC USE

Antiinfectives are also classified in the following groups:

A01AB Antiinfectives and antiseptics for local oral treatment
A02BD Combinations for eradication of Helicobacter pylori
A07A Intestinal antiinfectives
D01 Antifungals for dermatological use
D06 Antibiotics and chemotherapeutics for dermatological use
D07C Corticosteroids, combinations with antibiotics
D09AA Ointment dressings with antiinfectives
D10AF Antiinfectives for treatment of acne
G01 Gynecological antiinfectives and antiseptics
P Antiparasitic products, insecticides and repellents
R02AB Antibiotics
R05X Other cold preparations
S01/
S02/
S03 Eye and ear preparations with antiinfectives

Even systemically administered antibacterials and antimycotics may be classified in other groups if their target is exclusively local, e.g. the skin - D01 - Antifungals for dermatological use

Inhaled antiinfectives are classified in J.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'J'
and (dose_form not like 'Vagina%' and dose_form not like 'Topical%' and dose_form not like 'Otic%'
and dose_form not like 'Ophthalmic%' and dose_form not like 'Medicated%' and dose_form not like 'Irrigation%');
;

/*


New search    Hide text from Guidelines
L ANTINEOPLASTIC AND IMMUNOMODULATING AGENTS

This group comprises preparations used in the treatment of malignant neoplastic diseases, and immunomodulating agents.

Corticosteroids for systemic use, see H02.

L01 ANTINEOPLASTIC AGENTS

Combination products are classified in L01XY - Combinations of antineoplastic agents.

Detoxifying agents used in connection with high dose treatment of antineoplastic agents are classified in V03AF (e.g. calcium folinate)

No DDDs have been established because of highly individualised use and wide dosage ranges. The doses used vary substantially because of various types and severity of neoplastic diseases, and also because of the extensive use of combination therapy.

The consumption of the antineoplastic agents is in some countries measured in grams. This is recommended as a method to be used internationally for these particular agents.

L02 ENDOCRINE THERAPY

Estrogens and progestogens used specifically in the treatment of neoplastic diseases are classified in this group. This means that some strengths may be classified in this group, while remaining strengths are classified in G03 - Sex hormones and modulators of the genital system.

The DDDs are based on the treatment of cancer (breast-, endometrial, and prostatic).

L03 IMMUNOSTIMULANTS

Immunosuppressants, see L04A.

L04 IMMUNOSUPPRESSANTS

Immunosuppressants are defined as agents that completely or partly suppress one or more factors in the immunosystem.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'L'; /* Checked */

/*
M MUSCULO-SKELETAL SYSTEM

M01 ANTIINFLAMMATORY AND ANTIRHEUMATIC PRODUCTS
M02 TOPICAL PRODUCTS FOR JOINT AND MUSCULAR PAIN
M03 MUSCLE RELAXANTS

This group comprises peripherally, centrally and directly acting muscle relaxants.

See also G04BD - Drugs for urinary frequency and incontinence.

M04 ANTIGOUT PREPARATIONS
M05 DRUGS FOR TREATMENT OF BONE DISEASES

Drugs used for the treatment of bone diseases, see also:

A11CC - Vitamin D and analogues
A12A - Calcium
A12AX - Calcium, combinations with vitamin D and/or other drugs
A12CD - Fluoride
G03C/G03F - Estrogens/Progestogens and estrogens in combination
H05BA - Calcitonins

M09 OTHER DRUGS FOR DISORDERS OF THE MUSCULO-SKELETAL SYSTEM
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'M' and dose_form not like 'Ophthalmic%' 
and dose_form not like 'Ophthalmic%' and dose_form not like 'Nasal%';

/*

N NERVOUS SYSTEM

N01 ANESTHETICS

No DDDs have been established in this group because the doses used vary substantially.

N02 ANALGESICS

This group comprises general analgesics and antipyretics.

All salicylic acid derivatives except combinations with corticosteroids are classified in N02BA - Salicylic acid and derivatives, as it is difficult to differentiate between the use of salicylates in rheumatic conditions and other therapeutic uses of salicylates.

All ibuprofen preparations are classified in M01A, even if they are only intended for use as pain relief.

Salicylic acid derivatives in combination with corticosteroids are classified in M01B.

There are a number of combined preparations, which contain analgesics and psycholeptics. These are classified in N02, as pain relief must be regarded as the main indication. Analgesics used for specific indications are classified in the respective ATC groups. E.g.:

A03D/
A03EA - Antispasmodic/psycholeptics/analgesic combinations
M01 - Antiinflammatory and antirheumatic products
M02A - Topical products for joint and muscular pain
M03 - Muscle relaxants

See comments to these groups.

Lidocaine indicated for postherpetic pain is classified in N01BB.

N03 ANTIEPILEPTICS
N04 ANTI-PARKINSON DRUGS

This group comprises preparations used in the treatment of Parkinson's disease and related conditions, including drug-induced parkinsonism.

The DDDs are based on recommended doses for the long-term treatment of symptoms of Parkinson's disease.

No separate DDDs are established for oral depot formulations.

N05 PSYCHOLEPTICS

The group is divided into therapeutic subgroups:

N05A - Antipsychotics
N05B - Anxiolytics
N05C - Hypnotics and sedatives

N06 PSYCHOANALEPTICS

This group comprises antidepressants, psychostimulants, nootropics anti-dementia drugs and combinations with psycholeptics.

Antiobesity preparations are classified in A08 - Antiobesity preparations, excl. diet products.

N07 OTHER NERVOUS SYSTEM DRUGS

This group comprises other nervous system drugs, which cannot be classified in the preceding 2nd levels in ATC group N.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'N' and dose_form not like 'Ophthalmic%' 
and dose_form not like 'Ophthalmic%';

/*

P ANTIPARASITIC PRODUCTS, INSECTICIDES AND REPELLENTS

The group is subdivided according to types of parasites.

P01 ANTIPROTOZOALS
P02 ANTHELMINTICS

The anthelmintics are subdivided according to the main type of worms (i.e. trematodes, nematodes and cestodes) causing the infections.

P03 ECTOPARASITICIDES, INCL. SCABICIDES, INSECTICIDES AND REPELLENTS

No DDDs are assigned in this group. Substances classified in this group are for topical use and the consumption figures for these preparations could be expressed in e.g. grams of preparations regardless of strength.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'P'; /* Check v route */

/*


New search    Hide text from Guidelines
R RESPIRATORY SYSTEM

Inhaled antiinfectives are classified in ATC group J - Antiinfectives for systemic use.

R01 NASAL PREPARATIONS
R02 THROAT PREPARATIONS
R03 DRUGS FOR OBSTRUCTIVE AIRWAY DISEASES
R05 COUGH AND COLD PREPARATIONS

This group comprises a large number of preparations, most of which are combined preparations.

Cold preparations containing therapeutic levels of antiinfectives should be classified in ATC group J - Antiinfectives for systemic use.

Cold preparations with therapeutic levels of analgesics/anti-inflammatory agents should be classified in the respective N02/M01 groups, at separate 5th levels by using the 50-series.

Cold preparations with both antiinfectives and analgesics should be classified in ATC group J - Antiinfectives for systemic use.

Cold preparations with minimal amounts of antiinfectives or analgesics are classified in R05X - Other cold preparations.

See also R01 - Nasal preparations, R02 - Throat preparations, and R03D - Other systemic drugs for obstructive airway diseases.


Fixed DDDs are assigned for combinations. These DDDs are based on an average dose regimen of three times daily, and dosages in the upper area of the recommended dose ranges are chosen. The strengths of the various components are not taken into consideration. E.g. 6 UD (= 30 ml) is the fixed DDD for products where the recommended dose is 5-10 ml.

R06 ANTIHISTAMINES FOR SYSTEMIC USE
R07 OTHER RESPIRATORY SYSTEM PRODUCTS
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'R' and dose_form not like '%Ophthalmic%' 
and dose_form not like '%Topical%' and dose_form not like 'Medicated Pad' and dose_form not like '%Otic%' and dose_form not like '%Vaginal%'
and dose_form not like '%Rectal%'
; /* Need to filter routes e.g., nasal preparations */

/*
New search    Hide text from Guidelines
S SENSORY ORGANS

A formulation approved both for use in the eye/ear is classified in S03, while formulations only licensed for use in the eye or the ear are classified in S01 and S02, respectively.

S01 OPHTHALMOLOGICALS

Small amounts of antiseptics in eye preparations do not influence the classification, e.g. benzalconium.

See also S03 - Ophthalmological and otological preparations.

DDDs have been assigned for antiglaucoma preparations only.

S02 OTOLOGICALS

Small amounts of antiseptics in otological preparations do not influence the classification, e.g. benzalconium.

See also S03 - Ophthalmological and otological preparations.

No DDDs are assigned in this group.

S03 OPHTHALMOLOGICAL AND OTOLOGICAL PREPARATIONS

This group comprises preparations which can be used in both eye and ear.

Small amounts of antiseptics (e.g. benzalconium) in eye/ear preparations do not influence the classification.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'S' and (dose_form like 'Ophthalmic%' or dose_form like 'Otic%') ;

/*


New search    Hide text from Guidelines
V VARIOUS

This group comprises many different types of drugs, and assigning DDDs are difficult. Very few DDDs are assigned in this group.


V01 ALLERGENS
V03 ALL OTHER THERAPEUTIC PRODUCTS
V04 DIAGNOSTIC AGENTS
V06 GENERAL NUTRIENTS

This group comprises nutrients for oral use, incl. preparations used in feeding with stomach tube. Solutions for parenteral nutrition are classified in B05BA.

V07 ALL OTHER NON-THERAPEUTIC PRODUCTS
V08 CONTRAST MEDIA

This group comprises X-ray, MRI and Ultrasound contrast media. The X-ray contrast media are subdivided into iodinated and non-iodinated compounds, and are further classified according to water solubility, osmolarity and nephrotropic/hepatotropic properties. High osmolar substances correspond mainly to ionic substances, except from ioxaglic acid, which is classified together with the non-ionic substances. MRI contrast media are subdivided according to magnetic properties.

V09 DIAGNOSTIC RADIOPHARMACEUTICALS

An expert group consisting of Dik Blok (the Netherlands), Per Oscar Bremer (Norway) and Trygve Bringhammar (Sweden) is responsible for the ATC classification of radiopharmaceuticals in V09 and V10. The group has also prepared the guidelines for classification of these products.

Radiopharmaceuticals for diagnostic use are classified in this group, while radiopharmaceuticals for therapeutic use are classified in V10. In general, the 3rd level are subdivided according to site of action or organ system, the 4th level according to radionuclide and the 5th level specifies the chemical substance. The ATC 5th level defines the actual form essential in nuclear medicine procedures, which includes radionuclide and carrier molecule. Therefore, products on the market, that can often be regarded as intermediate products rather than ready-to-use radiopharmaceuticals, can be given more than one (5th level) ATC code, e.g. Technetium (99mTc) exametazime (V09AA01) and technetium (99mTc) exametazime labelled cells (V09HA02).

ATC codes are not assigned for radionuclide precursors which are used only in the radiolabelling of another substance prior to administration.

No DDDs have been assigned for radiopharmaceuticals.

V10 THERAPEUTIC RADIOPHARMACEUTICALS

Radiopharmaceuticals for therapeutic use are classified in this group, while radiopharmaceuticals for diagnostic use are classified in V09 - Diagnostic radiopharmaceuticals.

See comments to V09.
*/

select * from rxnorm_prescribe.atc_ingredient_link_to_in_rxcui2 where atc1 = 'V';

select distinct ATC1, ATC1_Name FROM rxnorm_prescribe.atc_ingredients