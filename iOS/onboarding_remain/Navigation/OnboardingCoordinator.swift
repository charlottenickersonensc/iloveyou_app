//
//  OnboardingCoordinator.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - App Routes
enum AppRoute: Hashable {
    case meetCommunity
    case welcomeSignUp
    case createAccount
    case verifyAccount(String)
    case termsAndConditions
    case beginCommunitySearch
    case joinCommunity
    case selectedCommunity
    case customizeProfile
    case customizeProfile2
    case customizePFP
    case onboard1
    case onboard2
    case onboard3
}

// MARK: - Onboarding Coordinator (Root Navigation)
struct OnboardingCoordinator: View {

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MeetYourCommunityView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .meetCommunity:
                        MeetYourCommunityView(path: $path)
                    case .welcomeSignUp:
                        WelcomeSignUpView(path: $path)
                    case .createAccount:
                        CreateAccountView(path: $path)
                    case .verifyAccount(let phone):
                        VerifyAccountView(phoneNumber: phone, path: $path)
                    case .termsAndConditions:
                        TermsAndConditionsView(path: $path)
                    case .beginCommunitySearch:
                        BeginCommunitySearchView(path: $path)
                    case .joinCommunity:
                        JoinCommunityView(path: $path)
                    case .selectedCommunity:
                        SelectedCommunityView(path: $path)
                    case .customizeProfile:
                        CustomizeProfileView(path: $path)
                    case .customizeProfile2:
                        CustomizeProfile2View(path: $path)
                    case .customizePFP:
                        CustomizePFPView(path: $path)
                    case .onboard1:
                        Onboard1View(path: $path)
                    case .onboard2:
                        Onboard2View(path: $path)
                    case .onboard3:
                        Onboard3View(path: $path)
                    }
                }
        }
    }
}
