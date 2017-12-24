

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Varariable definition  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
         index-stop-year  ; expected proportion of agents who would stop farming per year
         index-growth     ; difference in the expected agents' buying capacity per scenario
        ]


breed [agents agent]      ; an agent represent a farm


agents-own [
            ; AGENTS' WILLINGNESS AND ABILITY
               agent-type                 ; decision-making strategy

            ; AGENTS' ABILITY
               agent-id                   ; agent id
               agent-age                  ; age of the farm head
               agent-production           ; dsu. per ha
               agent-business-type        ; agribusiness type (e.g. livestock, intensive livestock, etc)
               agent-previous-transaction ; average transactions made between 2010-2015.
               agent-production-scale     ; total amount of dsu. (Dutch Standard Units; in 2015 1 dsu = � 1400)
               agent-production-extra     ; extra dsu per hectare due to differences between spatial data and census data (> 2 dsu/ha)
               agent-farm-size            ; farm size
               agent-farm-size-initial    ; initial farm size
               agent-farm-size-previous   ; simulated famr size
               agent-farm-list            ; list of owned patches
               agent-field-list           ; list of owned fields

            ; INTERNAL SYSTEM MEMORY: farm expansion
               agent-transactions         ; list of land transactions of the last 5 years
               agent-farm-expansion       ; land-changes: amount of land that the agent has bought or sell in the last year
               agent-farm-expansion-sum   ; land-changes: amount of land that the agent has bought or sell in the last 5 years
               agent-new                  ; whether the agent is an immigrant from the cities
               agent-field-sell           ; which field would be sold

            ; AGENTS' OPTIONS
              ; Thresholds between agents' options based on the agent type
                 p-stop-type              ; stop farming
                 p-expand-type            ; buy land
                 p-shrink-type            ; sell land

              ; farm feedbacks
                 p-expand-feedback        ; influence of the previous land transactions on future options.
                 p-stop-feedback          ; influence ot previous land transactions on stop farming
              ; exogenous processes
                 p-scenario-ehs           ; influence of the exogenous processes on the development of the EHS
              ; final probability
                 p-stop                   ; probability to stop farming
                 p-expand                 ; probability to expand farm
                 p-shrink                 ; probability to sell part of the land

              ; buyer selection
                 weight-buy               ; the sum of the other weighting values
                 weight-size              ; whether the farm is bigger than the farm to buy
                 weight-distance          ; whether the agent is close to the seller
                 weight-type              ; whether the agent is an expansionist

            ; AGENTS' DECISIONS & ACTIONS
               agent-cessation            ; stop farming or inherit farm.
               agent-expansion            ; buy, keep or sell.
               agent-random-stop          ; random number: decisions on farm cessation
               agent-random-expand        ; random number: decisions on farm expansion
               agent-random-shrink       ; random number: decisions on farm shrink
           ]


patches-own [
             ; DEFINITION OF THE PATCHES (PIXELS)
             patch-size-model       ; size of each patch in relation to the real field size
             patch-farm-size        ; area of the farm to which the patch belongs
             parcel-field-number    ; field to which the pixel belongs
             ; DEFINITION OF THE FIELDS
             field-owner-id         ; field owner
             field-size             ; size of the field
             field-distance-owner   ; distance to the agent's house
             field-landuse          ; land-use type of the field
             field-ehs              ; whether the field belongs to the area selected for the EHS
            ]







;;;;;;;;;;;;;;;;;;;;;;;;;;
;  MODEL INITIALISATION  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks                          ; clear all
  ; FIELDS
  definition-fields           ; define the landuse type and which pixels belongs to which field and how owns them.


  ; AGENTS
  definition-agents           ; create, allocate and characterise each agent for the first time

  ; AGENTS' INITIAL CONDITIONS
  option-agent-type           ; agent type probabilities
  option-agent-initial        ; initial agent's probability

  ; SCENARIO IMPLEMENTATION:

  ; AGENTS' INITIAL OPTIOINS & DECISIONS
  farm-cessation-option       ; initial likelihood to stop farming
  farm-cessation-decision     ; initial decision on farm cessation

  update-map                  ; land use changes
  update-plot                 ; plot changes

end







;;;;;;;;;;;;;;;
;  MODEL RUN  ;
;;;;;;;;;;;;;;;

to go
  tick                         ; a time step
  ; FEEDBACKS
  feedback-internal-decisions  ; represent the agent decision-making trajectory
  feedback-internal-actions    ; define the influence of previous actions

  ; OPTIONS
  farm-cessation-option        ; likelihood to stop farming
  farm-expansion-option        ; likelihood to buy/sell land

  ; DECISIONS
  farm-cessation-decision      ; who is going to stop farming
  farm-expansion-decision      ; who is going to buy/sell land


  ; ACTIONS
  farm-cessation-action        ; agents >= 50 years can stop farming or new agents can inherit the farm.
  farm-expansion-action        ; whether agents buy or sell fields


  ; UPDATES
  update-agent-transactions    ; update agent's farm size and transactions
  update-agent                 ; update agents' willingness and ability
  update-map                   ; update the land usez
  update-plot                  ; update all the plots

  ; STOP THE MODEL
  ; The period modelled is 2005 - 2020
  if (ticks = 15)
      [
       export-data            ; Save some data for further analyses
       stop                   ; The model stops
      ]

end






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INITIAL CONDITIONS & SUB-PROCESSSES ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; INPUT DATA
to definition-fields

  ; Reading external file to define the land-use type for each field
  file-open "land_types.txt"
  foreach sort patches [ask ? [set field-landuse file-read] ]
  file-close

  ; Reading external file to define which patches belong to the same field.
  file-open "fields_id.txt"
  foreach sort patches [ask ? [set parcel-field-number file-read] ]
  file-close

  ; Reading external file to define the size of each patch related to field size.
  file-open "fields_size.txt"
  foreach sort patches [ask ? [set field-size file-read] ]
  file-close

  ; Reading external file to define the size of each patch related to field size.
  file-open "fields_area.txt"
  foreach sort patches [ask ? [set patch-size-model file-read] ]
  file-close

  ; Reading external file to define which patches belong to the same agent.
  file-open "fields_owner.txt"
  foreach sort patches [ask ? [set field-owner-id file-read] ]
  file-close

  ; Reading external file to define the neighbour field.
  file-open "fields_ehs.txt"
  foreach sort patches [ask ? [set field-ehs file-read]]
  file-close


end





to definition-agents

  create-agents 2741 ; Number of agents in the study area based on the the file try_agent_id.txt
  ask agents [hide-turtle]

  random-seed new-seed  ; Defines a different set of random numbers each time the model is run

  ; Id: reading external file to define the Id of each agent.
  file-open "agent_id.txt"
  foreach sort agents [ask ? [set agent-id file-read]]
  file-close

  ; Location: reading external file to define the coordinates of each agent
  file-open "agent_x.txt"
  foreach sort agents [ask ? [set xcor file-read] ]
  file-close

  file-open "agent_y.txt"
  foreach sort agents [ask ? [set ycor file-read] ]
  file-close

  ; Agent type: reading external file to define agent type.
  file-open "agent_type.txt"
  foreach sort agents [ask ? [set agent-type file-read] ]
  file-close

  ; Age: reading external file to define agent's age.
  file-open "agent_age.txt"
  foreach sort agents [ask ? [set agent-age file-read] ]
  file-close

  ; Business: reading external file to define agent's business type.
  file-open "agent_business.txt"
  foreach sort agents [ask ? [set agent-business-type file-read] ]
  file-close

  ; Past land transactions: reading external file to define agents' land transactions between 2001-2005.
  file-open "agent_trans.txt"
  foreach sort agents [ask ? [set agent-previous-transaction file-read] ]
  file-close

  ; Production scale: reading external file to define agents' size of production per ha. in 2005 based on the area in the map.
  ; To reduce agents with a very high agent-production, a maximum was established based on agribusiness type, farm and production
  ; (empirical data). The difference of dsu for those higher than 90 percentile was added as agent-production-extra.
  file-open "agent_product.txt"
  foreach sort agents [ask ? [set agent-production file-read] ]
  file-close

  ; Production scale extra: reading external file to define the extra amount of dsu due to differences between the census data and the map.
  file-open "agent_product_extra.txt"
  foreach sort agents [ask ? [set agent-production-extra file-read] ]
  file-close



  ; Calculation of other agents' characteristics
  ask agents
      [
       set agent-transactions n-values 5 [agent-previous-transaction]            ; list the transactions (2001-2005) in five years
       set agent-farm-expansion-sum (sum agent-transactions)                     ; amount of land that an agent has bought/sold in the last 5 years
       set agent-farm-expansion 0                                                ; create the value of land-transaction
       set agent-farm-list patches with [field-owner-id = [agent-id] of myself]  ; create a list of patches that belong to each agent
       set agent-field-list remove-duplicates definition-farms                   ; redefine the list to the fields that belong to each agent
       set agent-farm-size (sum [patch-size-model] of agent-farm-list)           ; define the farm size
       set agent-farm-size-previous agent-farm-size                              ; define the previous farm size
       set agent-farm-size-initial (sum [patch-size-model] of agent-farm-list)   ; define the initial farm size
       set agent-cessation ""                                                    ; definition of the variable
      ]
  update-agent
end



to-report definition-farms []
  report [parcel-field-number] of agent-farm-list  ; This report lists all the fields that belong to each agent.
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UPDATE OF THE SUB-PROCESSES  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to update-agent

  ; Structure (no. patches) that belongs to each agent.
  ask agents
      [
       ; Define the production of each agent
       ifelse agent-farm-size < 1
           [set agent-production-scale (agent-production + agent-production-extra)]  ; This avoids the numerical problems of agents with very small farms.
           [set agent-production-scale ((agent-farm-size * agent-production) + agent-production-extra)]


       let patch-farm-area agent-farm-size            ; define the farm to which a patch belongs
       ask agent-farm-list
           [
            set field-distance-owner distance myself  ; define the distance of each patch to the agent-house
            set patch-farm-size patch-farm-area       ; define the size of the farm to which a patch belongs
           ]

         let mean-farmer-production-scale mean [agent-production-scale] of agents with [agent-type = 1]
         let mean-herdsman-production-scale mean [agent-production-scale] of agents with [agent-type = 2]
       ; Update the agent type of  agents
       if (agent-type = 1) and (agent-production-scale < mean-herdsman-production-scale)
           [
            set agent-type 2
            option-agent-type
           ]

       ; Changes between agent types
       if (agent-type = 2) and (agent-production-scale  < mean-farmer-production-scale)
           [
            set agent-type 1
            option-agent-type
           ]
        set agent-age (agent-age + 1)                        ; agents get older
      ]
end

to update-agent-transactions
ask agents [
            ; Update the list of action-agent-farm-expansion
            set agent-farm-size (sum [patch-size-model] of agent-farm-list)        ; update agents' farm size
            set agent-farm-expansion (agent-farm-size - agent-farm-size-previous)  ; whether an agent has previously expanded or decreased land
            set agent-farm-size-previous agent-farm-size                           ; define the current farm size as previous for the subsequent year
            set agent-transactions but-first agent-transactions                    ; delete the land transaction of the first year
            set agent-transactions lput agent-farm-expansion agent-transactions    ; add the land transactions of the current year
            set agent-farm-expansion-sum (sum agent-transactions)                  ; update the amount of land that an agent has bought/sold in the last 5 years
            let patch-farm-area agent-farm-size                                    ; define a variable that can be used for defining the farm to which a patch belongs
            ask agent-farm-list [set patch-farm-size patch-farm-area]              ; update the farm size to which a field belongs
          ]
end



to update-map
  view-land-use  ; The land use of the area is updated
end


to update-plot ; Different plots of the modelling process

  ; Graph of the relative number of agents per type
  set-current-plot "Percentage of agents"
  ;plot count agents
  set-current-plot-pen "Farmer"
  plot (count agents with [agent-type = 1] / count agents * 100)
  set-current-plot-pen "Herdsman"
  plot (count agents with [agent-type = 2] / count agents * 100)


  ; Graph of the mean farm size (ha) per agent type
  set-current-plot "Mean farm size"
  set-current-plot-pen "Farmer"
  plot (sum [agent-farm-size] of agents with [agent-type = 1]) / (count agents with [agent-type = 1])
  set-current-plot-pen "Herdsman"
  plot (sum [agent-farm-size] of agents with [agent-type = 2]) / (count agents with [agent-type = 2])


  ; Graph of the percentage of land managed per agent type
  set-current-plot "Percentage of area"
  set-current-plot-pen "Farmer"
  plot (sum [agent-farm-size] of agents with [agent-type = 1]) / (sum [agent-farm-size] of agents) * 100
  set-current-plot-pen "Herdsman"
  plot (sum [agent-farm-size] of agents with [agent-type = 2]) / (sum [agent-farm-size] of agents) * 100


  ; Graph of the amount of land
  set-current-plot "Land Area"
  set-current-plot-pen "Farmer"
  plot (sum [patch-size-model] of agents with [agent-type = 1])
  set-current-plot-pen "Herdsman"
  plot (sum [patch-size-model] of agents with [agent-type = 2])

  ; Graph of the total number of agents
  set-current-plot "Agents amount"
  ;set-current-plot-pen "Agents"
  ;plot count agents
  set-current-plot-pen "Farmer"
  plot (count agents with [agent-type = 1])
  set-current-plot-pen "Herdsman"
  plot (count agents with [agent-type = 2])

end



; DIFFERENT ALTERNATIVES TO VIEW THE STUDY AREA
to view-agent-type
  ask agents
      [
       if agent-type = 1 [ask agent-farm-list [set pcolor 45]]
       if agent-type = 2 [ask agent-farm-list [set pcolor 65]]
      ]
  ask patches
      [
       if field-landuse = 0      [set pcolor white]    ; No data
       if field-landuse = 6      [set pcolor white]    ; unused land
       if field-landuse = 5      [set pcolor white]    ; built-up
       if field-landuse = 4      [set pcolor white]    ; water
      ]

end





to view-land-use
  ask patches
      [

       if field-landuse = 0      [set pcolor white]    ; No data
       if field-landuse = 6      [set pcolor 5]       ; unused land
       if field-landuse = 5      [set pcolor 15]      ; built-up
       if field-landuse = 4      [set pcolor 105]       ; water
       if field-landuse = 3      [set pcolor 65]       ; grassland
       if field-landuse = 2      [set pcolor 55]       ; forestland
       if field-landuse = 1      [set pcolor 45]       ; cropland

      ]
end





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DEFINITION OF THE DIFFERENT PROBABILITIES ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to option-agent-initial
  ask agents
      [
       ; Based on the previous land transactions, the initial conditions are defined in this step for:

       ; Farm cessation
       set agent-random-stop random-float 1

       ; Farm expansion
       ifelse agent-farm-expansion-sum > 0.1
           [set agent-random-expand (random-float (p-expand-type + 0.1))]
           [ifelse agent-farm-expansion-sum < -0.1
                [set agent-random-expand ((0.9 - p-shrink-type) + random-float (p-shrink-type + 0.1))]
                [set agent-random-expand ((p-expand-type - 0.1) + random-float ((1 - p-shrink-type) - p-expand-type + 0.2))]
           ]
      ]
end



to option-agent-type

  ; are rescaled for 1 time step.

  ask agents
      [
       if agent-type = 1                    ; Farmer
           [
            set p-expand-type     0.01      ; Combined with p-shrink
            set p-shrink-type     0.05      ; Combined with p-expand, real value = 0.12
            set p-stop-type       0.34      ; Data based on farmers between 50-60 years old of the detailed survey
           ]
       if agent-type = 2                    ; Grassland
           [
            set p-expand-type     0.28      ; Combined with p-shrink
            set p-shrink-type     0.04      ; Combined with p-expand, real value = 0.11
            set p-stop-type       0.36      ; Data based on farmers between 50-60 years old of the detailed survey
           ]
     ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; QUANTIFICATION OF THE INFLUENCE OF PREVIOUS DECISIONS ON FUTURE OPTIONS ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to feedback-internal-actions
   ; Increase of the agents' buying capacity per scenario (assumed values)

   set index-growth 0.1

   ask agents
       [

        if (agent-type = 1)
            [set p-expand-feedback (0.05 + index-growth)]
        if (agent-type = 2)
            [set p-expand-feedback (0.2 + index-growth)]

                  ; previous transactions do not influence agents' options

        ; Propabibility that an agent will stop farming based on her/his previous transactions (empirical data)
        ; The value 0.14 is half of the difference between farmers older than 50 who bought and who didn't buy any land between
        if (agent-farm-expansion-sum < 0.1)  [set p-stop-feedback  0.14]
        if (agent-farm-expansion-sum >= 0.1) [set p-stop-feedback -0.14]
       ]

end




to feedback-internal-decisions ; influence of the previous in the subsequent random number
  ask agents
      [
       ; Based on the calibration of the amplitude of the curve, 0.06 was the selected value (calculated)
       set agent-random-expand random-normal agent-random-expand 0.06
       set agent-random-shrink random-normal agent-random-shrink 0.06

       ; Probabilities need to be between 0 and 1.
       if agent-random-expand < 0  [set agent-random-expand 0]
       if agent-random-expand > 1  [set agent-random-expand 1]
       if agent-random-shrink < 0  [set agent-random-shrink 0]
       if agent-random-shrink > 1  [set agent-random-shrink 1]
      ]
end


;;;;;;;;;;;;;;;;;;;
; AGENTS' OPTIONS ;
;;;;;;;;;;;;;;;;;;;

to farm-cessation-option
  ask agents
     [
      ; Those agents who haven't decided yet can decide whether to stop farming
      if (agent-cessation = "")
         [
          ; The likelihood to stop farming depends on agent type, the influence of the exogenous processes on the agent population
          ; and the agribusiness type, and the previous land transactions
          set p-stop (p-stop-type )  ; * p-stop-feedback
          ; Probabilities need to be between 0 and 1
          if p-stop < 0 [set p-stop 0]
          if p-stop > 1 [set p-stop 1]
         ]
     ]
end



to farm-expansion-option
  ask agents
      [
       ; The likelihood to buy/sell land depends on the agent type, the previous land transactions and
       ; the exogenous processes of each scenario
       set p-expand (p-expand-type )  ;* p-expand-feedback

       set p-shrink (p-shrink-type )
       ; Probabilities need to be between 0 and 1
       if p-expand < 0 [set p-expand 0]
       if p-expand > 1 [set p-expand 1]
       if p-shrink < 0 [set p-shrink 0]
       if p-shrink > 1 [set p-shrink 1]
      ]
end



to farm-shrink-option
  ; The likelihood to shrink/cut landscape elements only depends on the agent-type
  ask agents
      [
       set p-shrink (p-shrink-type)
      ]
end





;;;;;;;;;;;;;;;;;;;;;
; AGENTS' DECISIONS ;
;;;;;;;;;;;;;;;;;;;;;

to farm-cessation-decision
  ask agents
      [
       ; Agents older than 50 decide whether to stop or inherit their farms
       if agent-age > 50
         [
           ; This decision is the combination of a random number and the likelihood to stop farming
           ifelse (agent-random-stop < p-stop)
               [
                set agent-cessation "stop"
                ; TRANSITIONAL RUPTURE, agents who were expansionst become non-expansinist
                ; Their probabilities are recalculated, but they are 0.5 more likely to sell their farms (assumed)
                option-agent-type
                set agent-random-expand (0.5 + random-float 0.5)
               ]
               ; Those who don't stop will inherit their farm (no changes in agent type)
               [set agent-cessation "inherit"]
        ]
     ]
end




to farm-expansion-decision
  ask agents
      [
       ; The decision of buying land depends on three main factors:
       ifelse (p-expand > agent-random-expand) and    ; The agent wants to expand AND
       (agent-cessation != "stop")             and    ; the agent is not planning to stop farming AND
       (agent-farm-expansion-sum > -1)                ; the agent hasn't sold any land > 1ha. in the last five years.
              [set agent-expansion "buy"]
              [set agent-expansion "stable"]

       ; The decision of selling land depends on three factors
       if ((1 - p-shrink) < agent-random-expand) and  ; The agent wants to sell AND
       (length agent-field-list > 1)             and  ; the agent has more than 1 field AND
       (agent-farm-expansion-sum < 1)                 ; the agent hasn't bought any land > 1ha. in the last five years.
             [set agent-expansion "sell"]

      ]
end






;;;;;;;;;;;;;;;;;;;
; AGENTS' ACTIONS ;
;;;;;;;;;;;;;;;;;;;

to farm-cessation-action
   ; Depending on the scenario, the proportion of agents stopping farming each year varies. This has to be calculated per year (calculated, secondary data)

   set index-stop-year 0.1

   ask agents
       [
        ; only agents older than 65 years are able to inherit their farm
        if agent-cessation = "inherit" and agent-age >= 65
             [
              let percentage-agents random-float 1
              ; Agents younger than 84 have 0.1 likelihood to inherit their farm (empirical data)
              ; and agents 84 years old inherit the farm
              if (percentage-agents < 0.1) or (agent-age >= 84)
                    [
                     ; The new agent is 37 years old (empirical data) and follows the same strategy as the predecessor
                     set agent-age 37
                     set agent-cessation ""
                    ]
             ]


        if agent-cessation = "stop"
            [

             ; Based on a random number and the expected number of agent to stop per year or when they are older than 84, agents stop farming
             let percentage-agents random-float 1
             if (percentage-agents < index-stop-year) or (agent-age >= 84)
                 [


                   ; In the other sceanrios fields located in the EHS are abandoned
                   let fields-ehs patches with [(field-owner-id = [agent-id] of myself) and (field-ehs = 1)]

                        ask fields-ehs
                            [
                             set field-owner-id 9999
                             set field-landuse  4
                            ]
                        set agent-farm-list patches with [field-owner-id = [agent-id] of myself]
                        set agent-field-list remove-duplicates definition-farms

                        ; Those agent without any other field will quite
                        if (agent-farm-list = []) or (agent-field-list = []) [die]


                  ; From the land left, big farms (> 5 fields) are sold to different buyers (assumed)
                  while [length agent-field-list > 5]
                      [
                       ; Selection of the buyer
                       ; The buyer should be close to the seller
                       let agent-buyers min-n-of 5 agents with [agent-expansion = "buy"] [distance myself]
                       ask agent-buyers
                           [
                            ; the variables to selected the buyer are reset to change previous values
                            set weight-size 0
                            set weight-distance 0
                            set weight-type 0
                            ; the variables to select the buyer are re-calculated
                            let weight-random random-float 0.1
                            if agent-farm-size > [agent-farm-size] of myself [set weight-size 0.1]
                            if distance myself < 20 [set weight-distance 0.1]
                            if agent-type > 1 [set weight-type 0.1]
                            set weight-buy (weight-size + weight-distance + weight-type + weight-random)
                           ]
                       ; Selection of the buyer
                       let agent-buyer max-one-of agent-buyers [weight-buy]
                       ; Five fields to be sold are selected
                       let patches-sell n-of 5 agent-farm-list

                       ; Land transaction
                       ask patches-sell [set field-owner-id ([agent-id] of agent-buyer)]

                       ; Update the land owned and land transactions by the closest buyer
                       ask agent-buyer
                           [
                            set agent-farm-list patches with [field-owner-id = [agent-id] of myself]
                            ask agent-farm-list [set field-distance-owner distance myself]
                            set agent-field-list remove-duplicates definition-farms
                            set agent-expansion "bought"
                           ]
                        ; Update the farm of the seller
                        set agent-farm-list patches with [field-owner-id = [agent-id] of myself]
                        set agent-field-list remove-duplicates definition-farms
                       ]


                   ; Agents who are not new immigrants would continue selling their land
                   if agent-new = 0
                   [
                   ; The rest of big farms or small farms are sold to one buyer
                   ; The buyer should be close to the seller
                   let agent-buyers min-n-of 10 agents with [agent-expansion = "buy"] [distance myself]

                        ask agent-buyers
                            [
                             ; the variables to selected the buyer are reset
                             set weight-size 0
                             set weight-distance 0
                             set weight-type 0
                             ; the variables to select the buyer are calculated
                             let weight-random random-float 0.1
                             if agent-farm-size > [agent-farm-size] of myself [set weight-size 0.1]
                             if distance myself < 20 [set weight-distance 0.1]
                             if agent-type > 1 [set weight-type 0.1]
                             set weight-buy (weight-size + weight-distance + weight-type + weight-random)
                            ]
                   ; Selection of the buyer
                   let agent-buyer max-one-of agent-buyers [weight-buy]

                   ;; Land transaction
                   ask agent-farm-list [set field-owner-id ([agent-id] of agent-buyer)]

                   ; Update the land owned and land transactions by the closest buyer
                   ask agent-buyer
                       [
                        set agent-farm-list patches with [field-owner-id = [agent-id] of myself]
                        ask agent-farm-list [set field-distance-owner distance myself]
                        set agent-field-list remove-duplicates definition-farms
                        set agent-expansion "bought"
                       ]
                   ; The seller stops farming
                   die
                  ]
                  ]
             ]
       ]
end

to farm-expansion-action
  ; Transaction when an agent leases/sell only a field. This process also depends on the scenario.
  ask agents
    [
     if agent-expansion = "sell"
        [
                   set agent-field-sell (max-one-of agent-farm-list [field-distance-owner])

                   ; select the number of the field to which such a patch belongs
                   let parcel-field-number-sell ([parcel-field-number] of agent-field-sell)

                   ; Define the patches of that field
                   let patches-sell patches with [(parcel-field-number > 0) and (parcel-field-number = parcel-field-number-sell)]

                   ; Individual fields are sold to the closest buyer
                   let agent-closest-buyer min-one-of agents with [agent-expansion = "buy" or agent-expansion = "stable"] [distance myself]

                   ; The closest buyer gets the field
                   ask patches-sell [set field-owner-id ([agent-id] of agent-closest-buyer)]

                   ; Update the land owned and land transactions by the closest buyer
                   ask agent-closest-buyer
                        [
                         set agent-farm-list patches with [field-owner-id = [agent-id] of myself]
                         ask agent-farm-list [set field-distance-owner distance myself]
                         set agent-field-list remove-duplicates definition-farms
                         set agent-expansion "bought"
                        ]

                   ; Update land of the seller
                   set agent-farm-list patches with [field-owner-id = [agent-id] of myself]
                   set agent-field-list remove-duplicates definition-farms
                   set agent-field-sell []
                   set agent-expansion "sold"


                   ; Agents without more land left stop farming
                   if (agent-farm-list = []) or (agent-field-list = []) [die]

             ]
        ;]
    ]
end










;;;;;;;;;;;;;;;;;;;;
;  REPORT RESULTS  ;
;;;;;;;;;;;;;;;;;;;;


to-report export-next-index [prefix suffix]
  ; To create different output file names
  let index 0
  let filename (word prefix index suffix)
  while [file-exists? filename]
            [
             set index index + 1
             set filename (word prefix index suffix)
            ]
  report index
end


to export-data
  ; To export output
end
@#$#@#$#@
GRAPHICS-WINDOW
220
10
529
408
-1
-1
1.0
1
10
1
1
1
0
0
0
1
0
298
0
366
1
1
1
ticks
30.0

BUTTON
13
35
79
68
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
112
36
175
69
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
74
98
131
147
Agents
count agents
0
1
12

TEXTBOX
30
183
180
204
Views
20
105.0
1

BUTTON
20
256
127
289
land use
view-land-use
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
4
425
204
575
Percentage of agents
NIL
NIL
0.0
15.0
0.0
10.0
true
false
"" ""
PENS
"Agents" 1.0 0 -16777216 true "" ""
"Farmer" 1.0 0 -1184463 true "" ""
"Herdsman" 1.0 0 -13840069 true "" ""

PLOT
6
572
206
722
Percentage of area
NIL
NIL
0.0
15.0
0.0
10.0
true
false
"" ""
PENS
"Farmer" 1.0 0 -1184463 true "" ""
"Herdsman" 1.0 0 -13840069 true "" ""

PLOT
203
423
599
573
Mean farm size
time
dsu
0.0
15.0
0.0
10.0
true
true
"" ""
PENS
"Farmer" 1.0 0 -1184463 true "" ""
"Herdsman" 1.0 0 -13840069 true "" ""

PLOT
203
571
403
721
Land Area
NIL
NIL
0.0
15.0
0.0
10.0
true
false
"" ""
PENS
"Total" 1.0 0 -16777216 true "" ""
"Farmer" 1.0 0 -1184463 true "" ""
"Herdsman" 1.0 0 -13840069 true "" ""

PLOT
401
571
601
721
Agents amount
NIL
NIL
0.0
15.0
0.0
10.0
true
false
"" ""
PENS
"Farmer" 1.0 0 -1184463 true "" ""
"Herdsman" 1.0 0 -13840069 true "" ""

BUTTON
19
224
127
257
agent type
view-agent-type
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
