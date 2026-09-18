## Workout-session / Workout-unit / Jednostka treningowa

Workout session - trening, jednostka treningowa, jedno przyjście na siłownię, podczas workout session można zbierać ETU i FRU. Workout session składa się z listy exercise-unit.

## Exercise-Unit / Ćwiczenie
Para {exercise, zbiór setów}
## Set / Seria
Para {ilość powtórzeń (zakres), intensity: Literal['RIR0', 'RIR1', 'RIR2', 'RIR3', 'RIR4']}

## Rep / Repetitions / Powtórzenie
Brak modelu w systemie, widnieje jedynie jako zakres int w serii. Jest przydatny do ewaluacji CRU/PRU po exercise-unit.
## Intensity
Intensywność danego set'a. Pozwala oszacować ile wykonano tzw. Effective Reps. To jest przeliczane na ETU dla każdego mięśnia.

## ETU 

Effective Tension Unit.

Jednostka efektywnego napięcią mięśniowego. Wyrażana w cm^2 za pomocą szacukowego FCSA.

Jeśli dany mięsień ma FCSA na poziomie 18cm^2 i ćwiczenie dostarcza na ten mięsień dokładnie taki stimulus, to mówimy wtedy, że daje ono jedno normalized ETU.

Mięśni różnią się między sobą wielkością i dla modelowania regeneracji ma to znaczenie, więc taka skala jedna absolutna ale jednocześnie fallback na normalizacje jest super.

## Normalized ETU

1 efektywne powtórzenie na dany mięsień. Maksymalnie można uzyskać podczas serii takich 5.
