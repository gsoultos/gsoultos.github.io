---
title: Development Of Policy Administration Point For Attribute Based Access Control
date: 2023-02-12
tags:
    - abac
    - xacml
    - access-control
toc: true
header:
    teaser: /assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/cover.png
    overlay_image: /assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/cover.png
    overlay_filter: 0.6
---

# Introduction
This project was part of my thesis as undergraduate student. The purpose of this project was to develop a privacy access control platform, so non-technical users can easily create and manage ABAC policies without any prior knowledge of the Extensible Access Control Language (XACML).
<br>
In this article I will explain some of the basic concepts of access control and then I will go through my policy tool platform. If you are already familiar with access control, ABAC and XACML, you can checkout the policy tool description [here](#policy-tool) or you can download the tool directly from [here](https://github.com/gsoultos/policy-tool-docker).

# Access Control
Access control has a great importance in security and privacy fields. Each security violation has to do with inappropriate access to data or resources. Because of the complexity of today’s organizations/companies and the importance of the data that they manage, it’s critical the application of special designed privacy access control systems to protect privacy.
<br>
The purpose of access control systems is to permit or deny access to specific computer resources or data. There are a lot of access control algorithms/methodologies like DAC (Discretionary Access Control), MAC (Mandatory Access Control), RBAC (Role-Based Access Control) and ABAC (Attribute-Based Access Control). Each of them has it's own benefits and drawbacks but in this article we will only go though ABAC. That's because Attribute Based Access Control is one of the most advanced access control systems and it was the core of my thesis.

# ABAC
## What is ABAC?
Unlike other access control methodologies which are based on access control lists, role-based, etc, ABAC is an authorization model which is based on attributes. So in order to determine if a specific user is allowed to access a computer resource or data, it has to check the unique characteristics/attributes of this request. For example an attribute may be the profession of the user, the date of birth, the gender, the current physical location, etc. In other words the specific characteristics of the user may be more important than the actual identity of the user. It's worth to mention that the user may not be an actual person but a computer system.
<br>
The benefit of the Attribute Based Access Control is that it can enforce policies based on attributes/characteristics instead of the actual identity of the user.

## Components of ABAC
Let's talk about the components of ABAC. As I mention previously ABAC enforce access decisions based on the attributes of the request. The basic components of ABAC are: subject, resource, action and environment. For each of these components/categories we can define attributes that will be used during the enforcement process of the access control system.

### Subject
The subject component represents the subject of the user that is trying to access a specific resource. Subject category may refers to a user profile, a job role, a department or any kind of identifying criteria for the subject.
<br>
For example in case of a hospital, some possible attribute values for the subject category may be: Doctor, Nurse, Secretary, Patient, etc

### Resource
The resource component represents the actual resource that the subject is trying to gain access to. The resource category may refers to a specific file, computer system, file name or any kind of identifying criteria for the resource.
<br>
In our hospital example some possible attribute values for the resource category may be: Old medical records, Recent medical records, Private notes, Prescriptions, Appointment, etc

### Action
The action component represents the action that the subject is trying to execute on the resource. 
<br>
In our hospital example some possible attribute values for the action category may be: Add, Edit, View, Delete, All

### Environment
The environment component represents the broader context of each access request. It may referring to things like physical location, communication protocol, etc
<br>
In our hospital example some possible attribute values for the environment category may be: Hospital, Anywhere

# XACML
Until now we explained what access control is and more specifically what ABAC is. But how can we write ABAC policy rules so we can enforce access control? That where XACML come into play. XACML (eXtensible Access Control Markup Language) is an OASIS standard which is based on XML syntax and is used to define access control policies. It fully supports ABAC access control systems and it's considered the industry standard.
<br>
I won't go into the details of XACML syntax but you can read more about the language [here](https://medium.com/identity-beyond-borders/a-beginners-guide-to-xacml-6dc75b547d55)

> Official XACML documentation [here](http://docs.oasis-open.org/xacml/3.0/xacml-3.0-core-spec-os-en.html)

# Policy Tool
Now that we know what ABAC and XACML is, we can use the Policy Tool to create ABAC policies without actually know XACML syntax. In other words we will create some ABAC policies using the Policy Tool UI and with the click of a button we will generate the XACML code.
<br>
So lets start to creating the policy for our hospital example.

## Creating attributes

### Subject
First we will create an attribute for the Subject category named `Role` with attribute values: `Doctor`, `Nurse`, `Secretary` and `Patient`

![New Subject Attribute](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-new-subject.png)

### Resource
For the Resource category we will create an attribute named `File` with attribute values: `OldMedicalRecords`, `RecentMedicalRecords`, `PrivateNotes`, `Prescriptions` and `Appointment`

![New Resource Attribute](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-new-resource.png)

### Action
For the Action category we will create an attribute named `Action` with attribute values: `Add`, `Edit`, `View`, `Delete` and `All`

![New Action Attribute](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-new-action.png)

### Environment
Finlay for the Environment category we will create an attribute named `Location` with attribute values `Hospital` and `Anywhere`

![New Environment Attribute](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-new-environment.png)

## Attributes summary
We can see all the attributes for each category using the navigation menu.

![All Attributes](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-attributes.png)

## Creating ABAC policy
Now that we define out attributes and attribute values we can start creating out ABAC policy.
<br>
In our example we want doctors to have full access on `OldMedicalRecords`, `RecentMedicalRecords`, `PrivateNotes`, `Prescriptions` and only view access on `Appointment` data. All requests from doctors has to be from hospital's infrastructure, so they can’t access hospital’s files from their any other location.

| Role | OldMedicalRecords | RecentMedicalRecords | PrivateNotes | Prescriptions | Appointment |
| ---- | ----------------- | -------------------- | ------------ | ------------- | ----------- |
| Doctor | ALL / Hospital | All / Hospital | All / Hospital | All / Hospital | View / Hospital |

### Policy settings
First of all we have to configure some basic settings for our policy.

![Doctor policy settings](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-settings.png)

As you can see in the image above, we set policy description, policy ID, policy version and we can also configure settings like rule combining algorithm ID and max delegation depth.

### Target
Now lets configure our target policy. Here we have to specify under what circumstances we want our policy rules to be enforced.

![Doctor Target](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-target.png)

In our case we want the policy rules to be enforced when a doctor is trying to execute some request from the hospital's infrastructure. 

### Rules
Since we configure out target policy, lets start creating our policy rules.

<br>

First of all we will create a rule so doctors can gain full access to old medical records of their patients while they are using hospital's infrastructure.

![Doctor OldMedicalRecords Rule](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-rule-oldmedicalrecords.png)

Similarly we will create a rule for the recent medical records.

![Doctor RecentMedicalRecords Rule](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-rule-recentmedicalrecords.png)

Now lets create a rule for the private notes.

![Doctor PrivateNotes Rule](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-rule-privatenotes.png)

Rule for the prescription files.

![Doctor Prescriptions Rule](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-rule-prescriptions.png)

And finally we have to create a rule so doctors can gain only view access to the appointment data.

![Doctor Appointment Rule](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-rule-appointment.png)

Here is all the rules that we’ve created so far.

![Doctor Rules](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-doctor-rules.png)

### Policy summary
Below we can see our new ABAC policy. 

![ABAC Policies](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-abac-policies.png)

## Generating XACML code
Now that we created our ABAC policy it's time to generate the XACML code.
<br>
We can easily do that by navigating to the home screen of the policy tool platform, selecting the `doctor-policy` item from the policies drop-down menu and by clicking on `Generate ABAC Policy` button.
<br>
That's it! The XACML code has been generated and we can easily download the XML file.

![Generate XACML](/assets/images/development-of-policy-administration-point-for-attribute-based-acces-control/policy-tool-home.png)

> Note that there is also an option to save and load project.

Here is the generated XACML code for our doctor's policy:

``
<?xml version="1.0" encoding="UTF-8"?> <Policy xmlns="urn:oasis:names:tc:xacml:3.0:core:schema:wd-17" PolicyId="doctor-policy" Version="1" RuleCombiningAlgId="" MaxDelegationDepth="0"> <Description>Doctor policy</Description> <Target> <AnyOf> <AllOf> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Doctor</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:subject" AttributeId="Role" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Hospital</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:environment" AttributeId="Location" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> </AllOf> </AnyOf> </Target> <Rule RuleId="doctor-oldmedicalrecords-all-hospital-permit" Effect="Permit"> <Description>Doctor Old Medical Records All Hospital Permit</Description> <Target> <AnyOf> <AllOf> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Doctor</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:subject" AttributeId="Role" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">OldMedicalRecords</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:resource" AttributeId="File" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">All</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:action" AttributeId="Action" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Hospital</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:environment" AttributeId="Location" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> </AllOf> </AnyOf> </Target> </Rule> <Rule RuleId="doctor-recentmedicalrecords-all-hospital-permit" Effect="Permit"> <Description>Doctor Recent Medical Records All Hospital Permig</Description> <Target> <AnyOf> <AllOf> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Doctor</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:subject" AttributeId="Role" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">RecentMedicalRecords</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:resource" AttributeId="File" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">All</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:action" AttributeId="Action" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Hospital</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:environment" AttributeId="Location" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> </AllOf> </AnyOf> </Target> </Rule> <Rule RuleId="doctor-privatenotes-all-hospital-permit" Effect="Permit"> <Description>Doctor Private Notes All Hospital Permit</Description> <Target> <AnyOf> <AllOf> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Doctor</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:subject" AttributeId="Role" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">PrivateNotes</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:resource" AttributeId="File" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">All</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:action" AttributeId="Action" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Hospital</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:environment" AttributeId="Location" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> </AllOf> </AnyOf> </Target> </Rule> <Rule RuleId="doctor-prescriptions-all-hospital-permit" Effect="Permit"> <Description>Doctor Prescriptions All Hospital Permit</Description> <Target> <AnyOf> <AllOf> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Doctor</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:subject" AttributeId="Role" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Prescriptions</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:resource" AttributeId="File" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">All</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:action" AttributeId="Action" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Hospital</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:environment" AttributeId="Location" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> </AllOf> </AnyOf> </Target> </Rule> <Rule RuleId="doctor-appointment-view-hospital-permit" Effect="Permit"> <Description>Doctor Appointment View Hospital Permit</Description> <Target> <AnyOf> <AllOf> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Doctor</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:subject" AttributeId="Role" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Appointment</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:resource" AttributeId="File" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">View</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:action" AttributeId="Action" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> <Match MatchId="urn:oasis:names:tc:xacml:1.0:function:string-equal"> <AttributeValue DataType="string">Hospital</AttributeValue> <AttributeDesignator Category="urn:oasis:names:tc:xacml:3.0:attribute-category:environment" AttributeId="Location" DataType="string" Issuer="gsoultos" MustBePresent="true" /> </Match> </AllOf> </AnyOf> </Target> </Rule> </Policy>
``

> You can download the policy tool from [here](https://github.com/gsoultos/policy-tool-docker)

# References
- [A beginner’s guide to XACML](https://medium.com/identity-beyond-borders/a-beginners-guide-to-xacml-6dc75b547d55)
- [What Is Attribute-Based Access Control (ABAC)?](https://www.okta.com/blog/2020/09/attribute-based-access-control-abac/)
- [eXtensible Access Control Markup Language (XACML) Version 3.0](http://docs.oasis-open.org/xacml/3.0/xacml-3.0-core-spec-os-en.html)