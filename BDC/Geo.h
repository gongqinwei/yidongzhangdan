//
//  Geo.h
//  BDC
//
//  Created by Qinwei Gong on 2/19/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#ifndef BDC_Geo_h
#define BDC_Geo_h

#define US_FULL_INDEX   220
#define ADDR_DETAILS    [NSArray arrayWithObjects:@"Address1", @"Address2", @"Address3", @"Address4", @"City", @"State", @"Country", @"Zipcode", nil]

enum AddrType {
    kAddr1,
    kAddr2,
    kAddr3,
    kAddr4,
    kCity,
    kState,
    kCountry,
    kZip
};

#define COUNTRIES       [NSArray arrayWithObjects: \
@"USA", \
@"Afghanistan", \
@"Albania", \
@"Algeria", \
@"American Samoa", \
@"Andorra", \
@"Angola", \
@"Anguilla", \
@"Antarctica", \
@"Antigua and Barbuda", \
@"Argentina", \
@"Armenia", \
@"Aruba", \
@"Australia", \
@"Austria", \
@"Azerbaijan", \
@"Bahamas", \
@"Bahrain", \
@"Bangladesh", \
@"Barbados", \
@"Belarus", \
@"Belgium", \
@"Belize", \
@"Benin", \
@"Bermuda", \
@"Bhutan", \
@"Bolivia", \
@"Bosnia and Herzegovina", \
@"Botswana", \
@"Brazil", \
@"British Indian Ocean Territory", \
@"Brunei Darussalam", \
@"Bulgaria", \
@"Burkina Faso", \
@"Burundi", \
@"Cambodia", \
@"Cameroon", \
@"Canada", \
@"Cape Verde", \
@"Cayman Islands", \
@"Central African Republic", \
@"Chad", \
@"Chile", \
@"China", \
@"Christmas Island", \
@"Cocos (Keeling) Islands", \
@"Colombia", \
@"Comoros", \
@"Congo", \
@"Congo, Democratic Republic", \
@"Cook Islands", \
@"Costa Rica", \
@"Cote d'Ivoire", \
@"Croatia", \
@"Cyprus", \
@"Czech Republic", \
@"Denmark", \
@"Djibouti", \
@"Dominica", \
@"Dominican Republic", \
@"East Timor", \
@"Ecuador", \
@"Egypt", \
@"El Salvador", \
@"Equatorial Guinea", \
@"Eritrea", \
@"Estonia", \
@"Ethiopia", \
@"Falkland Islands (Malvinas)", \
@"Faroe Islands", \
@"Fiji", \
@"Finland", \
@"France", \
@"French Guiana", \
@"French Polynesia", \
@"French Southern Territories", \
@"Gabon", \
@"Gambia", \
@"Georgia", \
@"Germany", \
@"Ghana", \
@"Gibraltar", \
@"Greece", \
@"Greenland", \
@"Grenada", \
@"Guadeloupe", \
@"Guam", \
@"Guatemala", \
@"Guinea", \
@"Guinea-Bissau", \
@"Guyana", \
@"Haiti", \
@"Heard and McDonald Islands", \
@"Honduras", \
@"Hong Kong", \
@"Hungary", \
@"Iceland", \
@"India", \
@"Indonesia", \
@"Iraq", \
@"Ireland", \
@"Israel", \
@"Italy", \
@"Jamaica", \
@"Japan", \
@"Jordan", \
@"Kazakhstan", \
@"Kenya", \
@"Kiribati", \
@"Kuwait", \
@"Kyrgyzstan", \
@"Lao People's Democratic Rep.", \
@"Latvia", \
@"Lebanon", \
@"Lesotho", \
@"Liberia", \
@"Libya", \
@"Liechtenstein", \
@"Lithuania", \
@"Luxembourg", \
@"Macau", \
@"Macedonia", \
@"Madagascar", \
@"Malawi", \
@"Malaysia", \
@"Maldives", \
@"Mali", \
@"Malta", \
@"Marshall Islands", \
@"Martinique", \
@"Mauritania", \
@"Mauritius", \
@"Mayotte", \
@"Mexico", \
@"Micronesia", \
@"Moldova", \
@"Monaco", \
@"Mongolia", \
@"Montenegro", \
@"Montserrat", \
@"Morocco", \
@"Mozambique", \
@"Namibia", \
@"Nauru", \
@"Nepal", \
@"Netherlands", \
@"Netherlands Antilles", \
@"New Caledonia", \
@"New Zealand", \
@"Nicaragua", \
@"Niger", \
@"Nigeria", \
@"Niue", \
@"Norfolk Island", \
@"Northern Mariana Islands", \
@"Norway", \
@"Oman", \
@"Pakistan", \
@"Palau", \
@"Palestinian Territory", \
@"Panama", \
@"Papua New Guinea", \
@"Paraguay", \
@"Peru", \
@"Philippines", \
@"Pitcairn", \
@"Poland", \
@"Portugal", \
@"Puerto Rico", \
@"Qatar", \
@"Reunion", \
@"Romania", \
@"Russian Federation", \
@"Rwanda", \
@"Samoa", \
@"San Marino", \
@"Sao Tome and Principe", \
@"Saudi Arabia", \
@"Senegal", \
@"Serbia", \
@"Seychelles", \
@"Sierra Leone", \
@"Singapore", \
@"Slovakia", \
@"Slovenia", \
@"Solomon Islands", \
@"Somalia", \
@"South Africa", \
@"South Georgia and S.S. Islands", \
@"South Korea", \
@"Spain", \
@"Sri Lanka", \
@"St Kitts and Nevis", \
@"St Lucia", \
@"St Vincent and the Grenadines", \
@"St. Helena", \
@"St. Pierre and Miquelon", \
@"Suriname", \
@"Svalbard and Jan Mayen Islands", \
@"Swaziland", \
@"Sweden", \
@"Switzerland", \
@"Taiwan", \
@"Tajikistan", \
@"Tanzania", \
@"Thailand", \
@"Togo", \
@"Tokelau", \
@"Tonga", \
@"Trinidad and Tobago", \
@"Tunisia", \
@"Turkey", \
@"Turkmenistan", \
@"Turks and Caicos Islands", \
@"Tuvalu", \
@"U.S. Minor Outlying Islands", \
@"Uganda", \
@"Ukraine", \
@"United Arab Emirates", \
@"United Kingdom", \
@"United States", \
@"Uruguay", \
@"Uzbekistan", \
@"Vanuatu", \
@"Vatican", \
@"Venezuela", \
@"Viet Nam", \
@"Virgin Islands (British)", \
@"Virgin Islands (U.S.)", \
@"Wallis and Futuna Islands", \
@"Western Sahara", \
@"Yemen", \
@"Zambia", \
@"Zimbabwe", \
nil]


#define US_STATES       [NSArray arrayWithObjects: \
@"Alabama [AL]", \
@"Alaska [AK]", \
@"Arizona [AZ]", \
@"Arkansas [AR]", \
@"California [CA]", \
@"Colorado [CO]", \
@"Connecticut [CT]", \
@"Delaware [DE]", \
@"District of Columbia [DC]", \
@"Florida [FL]", \
@"Georgia [GA]", \
@"Hawaii [HI]", \
@"Idaho [ID]", \
@"Illinois [IL]", \
@"Indiana [IN]", \
@"Iowa [IA]", \
@"Kansas [KS]", \
@"Kentucky [KY]", \
@"Louisiana [LA]", \
@"Maine [ME]", \
@"Maryland [MD]", \
@"Massachusetts [MA]", \
@"Michigan [MI]", \
@"Minnesota [MN]", \
@"Mississippi [MS]", \
@"Missouri [MO]", \
@"Montana [MT]", \
@"Nebraska [NE]", \
@"Nevada [NV]", \
@"New Hampshire [NH]", \
@"New Jersey [NJ]", \
@"New Mexico [NM]", \
@"New York [NY]", \
@"North Carolina [NC]", \
@"North Dakota [ND]", \
@"Ohio [OH]", \
@"Oklahoma [OK]", \
@"Oregon [OR]", \
@"Pennsylvania [PA]", \
@"Puerto Rico [PR]", \
@"Rhode Island [RI]", \
@"South Carolina [SC]", \
@"South Dakota [SD]", \
@"Tennessee [TN]", \
@"Texas [TX]", \
@"Utah [UT]", \
@"Vermont [VT]", \
@"Virgin Islands [VI]", \
@"Virginia [VA]", \
@"Washington [WA]", \
@"West Virginia [WV]", \
@"Wisconsin [WI]", \
@"Wyoming [WY]", \
@"American Samoa [AS]", \
@"Federated States of Micronesia [FM]", \
@"Guam [GU]", \
@"Marshall Islands [MH]", \
@"Military Americas, Florida [AA]", \
@"Military California, Pacific [AP]", \
@"Military International, New York [AE]", \
@"Northern Mariana Islands [MP]", \
@"Palau [PW]", \
nil]

#define US_STATE_CODES       [NSArray arrayWithObjects: \
@"AL", \
@"AK", \
@"AZ", \
@"AR", \
@"CA", \
@"CO", \
@"CT", \
@"DE", \
@"DC", \
@"FL", \
@"GA", \
@"HI", \
@"ID", \
@"IL", \
@"IN", \
@"IA", \
@"KS", \
@"KY", \
@"LA", \
@"ME", \
@"MD", \
@"MA", \
@"MI", \
@"MN", \
@"MS", \
@"MO", \
@"MT", \
@"NE", \
@"NV", \
@"NH", \
@"NJ", \
@"NM", \
@"NY", \
@"NC", \
@"ND", \
@"OH", \
@"OK", \
@"OR", \
@"PA", \
@"PR", \
@"RI", \
@"SC", \
@"SD", \
@"TN", \
@"TX", \
@"UT", \
@"VT", \
@"VI", \
@"VA", \
@"WA", \
@"WV", \
@"WI", \
@"WY", \
@"AS", \
@"FM", \
@"GU", \
@"MH", \
@"AA", \
@"AP", \
@"AE", \
@"MP", \
@"PW", \
nil]


#endif

