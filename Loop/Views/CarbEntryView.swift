//
//  CarbEntryView.swift
//  Loop
//
//  Created by Noah Brauner on 7/19/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit

struct CarbEntryView: View, HorizontalSizeClassOverride {
    @EnvironmentObject private var displayGlucosePreference: DisplayGlucosePreference
    @Environment(\.dismissAction) private var dismiss

    @ObservedObject var viewModel: CarbEntryViewModel
        
    @State private var expandedRow: Row?
    
    @State private var showHowAbsorptionTimeWorks = false
    
    private let isNewEntry: Bool

    init(viewModel: CarbEntryViewModel) {
        if viewModel.shouldBeginEditingQuantity {
            expandedRow = .amountConsumed
        }
        isNewEntry = viewModel.originalCarbEntry == nil
        self.viewModel = viewModel
    }
    
    var body: some View {
        if isNewEntry {
            NavigationView {
                let title = NSLocalizedString("carb-entry-title-add", value: "Add Carb Entry", comment: "The title of the view controller to create a new carb entry")
                content
                    .navigationBarTitle(title, displayMode: .inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            dismissButton
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            continueButton
                        }
                    }
                
            }
        }
        else {
            content
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        continueButton
                    }
                }
        }
    }
    
    private var content: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                mainCard
                    .padding(.top, 8)
                
                continueActionButton
                
                let isBolusViewActive = Binding(get: { viewModel.bolusViewModel != nil }, set: { _, _ in viewModel.bolusViewModel = nil })
                NavigationLink(destination: bolusView, isActive: isBolusViewActive) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibility(hidden: true)
            }
        }
        .alert(item: $viewModel.alert, content: alert(for:))
        .sheet(isPresented: $showHowAbsorptionTimeWorks) {
            HowAbsorptionTimeWorksView()
        }
    }
    
    private var mainCard: some View {
        VStack(spacing: 10) {
            CarbQuantityRow(quantity: $viewModel.carbsQuantity, title: NSLocalizedString("Amount Consumed", comment: "Label for carb quantity entry row on carb entry screen"), preferredCarbUnit: viewModel.preferredCarbUnit, expandedRow: $expandedRow, row: Row.amountConsumed)

            CardSectionDivider()
            
            DatePickerRow(date: $viewModel.time, minimumDate: viewModel.minimumDate, maximumDate: viewModel.maximumDate, expandedRow: $expandedRow, row: Row.time)
            
            CardSectionDivider()
            
            FoodTypeRow(foodType: $viewModel.foodType, absorptionTime: $viewModel.absorptionTime, selectedDefaultAbsorptionTimeEmoji: $viewModel.selectedDefaultAbsorptionTimeEmoji, usesCustomFoodType: $viewModel.usesCustomFoodType, absorptionTimeWasEdited: $viewModel.absorptionTimeWasEdited, defaultAbsorptionTimes: viewModel.defaultAbsorptionTimes, expandedRow: $expandedRow, row: .foodType)
            
            CardSectionDivider()
            
            AbsorptionTimePickerRow(absorptionTime: $viewModel.absorptionTime, validDurationRange: viewModel.absorptionRimesRange, expandedRow: $expandedRow, row: Row.absorptionTime, showHowAbsorptionTimeWorks: $showHowAbsorptionTimeWorks)
                .padding(.bottom, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(CardBackground())
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var bolusView: some View {
        if let viewModel = viewModel.bolusViewModel {
            BolusEntryView(viewModel: viewModel)
                .environmentObject(displayGlucosePreference)
                .environment(\.dismissAction, dismiss)
        }
    }
    
    private func clearExpandedRow() {
        self.expandedRow = nil
    }
    
    private func alert(for alert: CarbEntryViewModel.Alert) -> SwiftUI.Alert {
        switch alert {
        case .maxQuantityExceded:
            let message = String(
                format: NSLocalizedString("The maximum allowed amount is %@ grams.", comment: "Alert body displayed for quantity greater than max (1: maximum quantity in grams)"),
                NumberFormatter.localizedString(from: NSNumber(value: viewModel.maxCarbEntryQuantity.doubleValue(for: viewModel.preferredCarbUnit)), number: .none)
            )
            let okMessage = NSLocalizedString("com.loudnate.LoopKit.errorAlertActionTitle", value: "OK", comment: "The title of the action used to dismiss an error alert")
            return SwiftUI.Alert(
                title: Text("Large Meal Entered", comment: "Title of the warning shown when a large meal was entered"),
                message: Text(message),
                dismissButton: .cancel(Text(okMessage), action: viewModel.clearAlert)
            )
        case .warningQuantityValidation:
            let message = String(
                format: NSLocalizedString("Did you intend to enter %1$@ grams as the amount of carbohydrates for this meal?", comment: "Alert body when entered carbohydrates is greater than threshold (1: entered quantity in grams)"),
                NumberFormatter.localizedString(from: NSNumber(value: viewModel.carbsQuantity ?? 0), number: .none)
            )
            return SwiftUI.Alert(
                title: Text("Large Meal Entered", comment: "Title of the warning shown when a large meal was entered"),
                message: Text(message),
                primaryButton: .default(Text("No, edit amount", comment: "The title of the action used when rejecting the the amount of carbohydrates entered."), action: viewModel.clearAlert),
                secondaryButton: .cancel(Text("Yes", comment: "The title of the action used when confirming entered amount of carbohydrates."), action: viewModel.clearAlertAndContinueToBolus)
            )
        }
    }
}

extension CarbEntryView {
    private var dismissButton: some View {
        Button(action: dismiss) {
            Text("Cancel")
        }
    }
    
    private var continueButton: some View {
        Button(action: viewModel.continueToBolus) {
            Text("Continue")
        }
        .disabled(viewModel.continueButtonDisabled)
    }
    
    private var continueActionButton: some View {
        Button(action: viewModel.continueToBolus) {
            Text("Continue")
        }
        .buttonStyle(ActionButtonStyle())
        .padding()
        .disabled(viewModel.continueButtonDisabled)
    }
}

extension CarbEntryView {
    enum Row {
        case amountConsumed, time, foodType, absorptionTime
    }
}
