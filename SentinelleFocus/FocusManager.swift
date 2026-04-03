// MARK: - DeviceActivity Monitoring
    private func scheduleDeviceActivityMonitoring(session: FocusSession) {
        let deviceActivityCenter = DeviceActivityCenter()
        
        // 1. On définit un nom unique pour notre activité
        let activityName = DeviceActivityName("sentinelle.focus.session")
        
        // 2. On définit un nom pour l'événement (le seuil de temps)
        let eventName = DeviceActivityEvent.Name("sentinelle.event.threshold")
        
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute], from: session.startDate),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute], from: session.endDate),
            repeats: false
        )
        
        // 3. On crée l'événement proprement dit
        let event = DeviceActivityEvent(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            threshold: DateComponents(minute: 1) // Seuil avant notification/action
        )
        
        do {
            // 4. On lance le monitoring avec le dictionnaire [Nom: Evénement]
            try deviceActivityCenter.startMonitoring(
                activityName, 
                during: schedule, 
                events: [eventName: event]
            )
            print("[FocusManager] Monitoring démarré avec succès")
        } catch {
            print("[FocusManager] DeviceActivity error: \(error)")
        }
    }