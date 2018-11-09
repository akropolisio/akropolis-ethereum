

# Akropolis Protocol Implementation

![Akropolis](https://bitcoinvietnamnews.com/wp-content/uploads/2018/08/akropolis-coin.jpg)


# Journeys

The goal of the MVP is to demonstrate how the core components and network participants interact. Below are a few defined journeys that build on one another to showcase this interaction as a progression of events.

1. Fund Creation (Role: Sponsor)
  1. Authentication via metamask
  2. Select “Create a Fund” on the home screen
  3. Complete descriptive fields and set lockup/fee
  4. Leave manager and directors addresses blank
    1. Automatically assigned to the sponsor
  5. Fee requirements 
    1. Will have necessary fee balances ahead of running the demo. This will ensure we are not wasting time waiting for transactions to be completed
  6. Deploy board and fund
  7. Stake AKT
  8. Select “View Funds” menu item
  9. Select newly created fund and view fund detail 
  10. Click on manager dashboard and confirm it’s what was specified
2. Initial Asset Allocation (Role: FM)
  1. Authentication via metamask
  2. Select “View Funds” menu item
  3. Select the fund created above
  4. Select Manager Dashboard
  5. Setup a transfer
    1. View director approved investible tokens
    2. Select quantity, address, transfer in, approve
  6. View Fund detail
    1. Change should be reflected
3. Join a Fund & Setup Recurring Contributions (Role: Individual)
  1. Authentication via metamask
    1. Don’t use same account as above fund creation steps
  2. Select “View Funds” menu item
  3. Select above created fund and view fund detail 
  4. Select “Apply to Join”
  5. Switch windows to the Manager screen
    1. View join request
    2. Accept join request
  6. Switch back to Individual user window
  7. View fund detail (should be approved)
  8. Setup a recurring contribution
  9. View contributions and history
## Functionality (by Role)

General

- Authentication via metamask 

Individual

- View available funds & apply to join as an individual
  - Fund detail & composition
  - Apply to join
- View funds invested in
- Make a contribution (one time or recurring)
  - Must be a member
- View contribution history

Fund Manager

- Create a digital fund
  - Name, symbol, risk, description
  - Lockup, Management Fee
  - Manger & BOD assignment
  - Deploy contract
- Move tokens in/out of fund
  - Governed by BOD approved investible tokens
- Fund Manager approval/rejection of individual join request

Sponsor/Originator 

- Create a digital fund (as defined above)

Board of Directors

- Initiate a motion
  - set/change manager
    - Only motion that is currently supported
- Voting on Motions



# Support
Join our support server at https://discord.gg/GZWaZCP for the latest news and information!


# License
Akropolis-Ethereum is released under the MIT License.
