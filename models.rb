# Account
{
    owner: 1, # id of user in uis system
    points_amount: 100,
    creation_date: '',
    transactions: [ instances of Transaction ],
    applications: [ instances of Application ],
    orders: [ instances of Order ]
}

# Transaction
{
    id: 123,
    amount: 100,
    amount_to_spend: 100,
    receiving_date: '',
    expiration_date: '',
    status: '', # active/expired/spent
}

# Application
{
    _id: 123,
    author: 1, # id of user in uis system,
    type: '', # personal/group
    personal: {
        work: {
            activity: 'instance of Activity',
            amount: 1, # null for permanent activity
        }
    },
    group: {
        work: [
            {
                actor: 1, # if of user in uis system
                activity: 'instance of Activity',
                amount: 1, # null for permanent
            }
        ]
    },
    files: [
        {
            _id: 123,
            filename: 'asd.jpg'
        }
    ],
    comment: '',
    status: '', # in_process/rejected/approved/rework
    creation_date: ''
}

# ApplicationsArchive

{
    author: 1, # // id of user in accounts microservice
    application_id: 123, # // application id
    status: 'rejected' # // or 'approved'
}

# ApplicationsInWork

{
    author: 1, # // id of user in accounts microservice
    application_id: 123, # // application id
    status: 'in_process' # // or 'rework'
}

#

# Order

{
    account: 'account id',
    items: [ instances of ShopItem ],
    total_price: 100,
    status: '' # in_process, approved, rejected, waiting_to_process, rejected_by_contributor, deleted
}
# Activity

{
    title: '',
    type: '', # hourly/quantity/permanent
    category: 'instance of Category',
    comment: '',
    for_approval: '',
    price: 100 # price for one hour, for permanent action or for one action
}

# Category

{
    title: ''
}

# Approved_apps

{
    token: ''
}

# Administrator

{
    user: 1, # id of user in uis system
    applications: [instance of Application]
}

# Item

{
    name: '',
    category: 'instance of ItemCategory',
    description: '',
    quantity: 1,
    price: 100
}

# ItemCategory

{
    title: ''
}

