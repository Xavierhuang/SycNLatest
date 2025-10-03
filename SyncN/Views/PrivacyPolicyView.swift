import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.custom("Sofia Pro", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Sync N Fitness Cycle Syncing version 1")
                            .font(.custom("Sofia Pro", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Effective Date: 9-9-2025")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Section 1: Introduction
                    PolicySection(
                        title: "1. Introduction",
                        content: "Sync N Inc (\"we,\" \"us,\" or \"our\") operates the Sync N Fitness Cycle Syncing mobile application (\"App\"). This Privacy Policy informs you of our policies regarding the collection, use, and disclosure of personal information when you use our App and the choices you have associated with that data."
                    )
                    
                    // Section 2: Information Collection and Use
                    PolicySection(
                        title: "2. Information Collection and Use",
                        content: "We collect several different types of information for various purposes to provide and improve our App to you."
                    )
                    
                    PolicySubsection(
                        title: "Personal Data",
                        content: "While using our App, we may ask you to provide us with certain personally identifiable information that can be used to contact or identify you (\"Personal Data\"). Personally identifiable information may include, but is not limited to:\n\n• Email address\n• First name and last name\n• Phone number\n• Address, State, Province, ZIP/Postal code, City\n• Cookies and Usage Data"
                    )
                    
                    PolicySubsection(
                        title: "Usage Data",
                        content: "When you access the App by or through a mobile device, we may collect certain information automatically, including, but not limited to, the type of mobile device you use, your mobile device unique ID, the IP address of your mobile device, your mobile operating system, the type of mobile Internet browser you use, unique device identifiers and other diagnostic data (\"Usage Data\")."
                    )
                    
                    // Section 3: Tracking & Cookies Data
                    PolicySection(
                        title: "3. Tracking & Cookies Data",
                        content: "We use cookies and similar tracking technologies to track the activity on our App and hold certain information. Cookies are files with a small amount of data which may include an anonymous unique identifier. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent. However, if you do not accept cookies, you may not be able to use some portions of our App."
                    )
                    
                    // Section 4: Use of Data
                    PolicySection(
                        title: "4. Use of Data",
                        content: "Sync N Inc uses the collected data for various purposes:\n\n• To provide and maintain our App\n• To notify you about changes to our App\n• To allow you to participate in interactive features of our App when you choose to do so\n• To provide customer support\n• To gather analysis or valuable information so that we can improve our App\n• To monitor the usage of our App\n• To detect, prevent, and address technical issues"
                    )
                    
                    // Section 5: Transfer of Data
                    PolicySection(
                        title: "5. Transfer of Data",
                        content: "Your information, including Personal Data, may be transferred to — and maintained on — computers located outside of your state, province, country, or other governmental jurisdiction where the data protection laws may differ from those from your jurisdiction. If you are located outside USA and choose to provide information to us, please note that we transfer the data, including Personal Data, to USA and process it there."
                    )
                    
                    // Section 6: Disclosure of Data
                    PolicySection(
                        title: "6. Disclosure of Data",
                        content: "We may disclose your Personal Data in the good faith belief that such action is necessary to:\n\n• To comply with a legal obligation\n• To protect and defend the rights or property of Sync N Inc\n• To prevent or investigate possible wrongdoing in connection with the App\n• To protect the personal safety of users of the App or the public\n• To protect against legal liability"
                    )
                    
                    // Section 7: Service Providers
                    PolicySection(
                        title: "7. Service Providers",
                        content: "We may employ third-party companies and individuals to facilitate our App (\"Service Providers\"), to provide the App on our behalf, to perform App-related services or to assist us in analyzing how our App is used. These third parties have access to your Personal Data only to perform these tasks on our behalf and are obligated not to disclose or use it for any other purpose."
                    )
                    
                    // Section 8: Links to Other Sites
                    PolicySection(
                        title: "8. Links to Other Sites",
                        content: "Our App may contain links to other sites that are not operated by us. If you click on a third party link, you will be directed to that third party's site. We strongly advise you to review the Privacy Policy of every site you visit. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third party sites or services."
                    )
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ContactInfoRow(icon: "envelope", text: "hello@syncnapp.com")
                            ContactInfoRow(icon: "globe", text: "www.syncnapp.com")
                            ContactInfoRow(icon: "location", text: "75 E 3rd St Ste 7, Sheridan, Wy 82801")
                        }
                        
                        Text("Lizzy Palmer\nFounder/CEO\nSync N Inc")
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text("Last updated: 2-24-2025")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                }
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Sofia Pro", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PolicySubsection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Sofia Pro", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ContactInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
