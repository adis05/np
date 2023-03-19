let _baPage = '#bossactions-page-employees';
let grades = 0;

function getEmployees() {
    $('#bossactions-employees tbody').html('');

    fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
        method: 'POST',
        body: JSON.stringify({
            'function': 'society',
            'event': 'getEmployees',
            'job': loggedInUser.job
        })
    })
    .then( response => response.json() )
    .then( data => {
        $('#employees-count').text( Object.keys( data ).length );

        Object.keys( data ).forEach(( k ) => {
            let promote = parseInt(data[k].job.grade) + 1;
            let demote = parseInt(data[k].job.grade) - 1;
            let div = `<tr>
                <td>${ data[k].name }</td>
                <td grade="${ data[k].job.grade }">${ data[k].job.grade_label }</td>
                <td class="right">
                    <p class="ba-promote" onclick="baChangeGrade('${ data[k].identifier }', '${ promote }')">Promote</p>
                    <p class="ba-demote" onclick="baChangeGrade('${ data[k].identifier }', '${ demote }')">Demote</p>
                    <p class="ba-fire" onclick="baFire('${ data[k].identifier }')">Fire</p>
                </td>
            </tr>`;

            $('#bossactions-employees tbody').append( div );
        });
    });
}

function getSalary() {
    $('#bossactions-salary tbody').html('');

    fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
        method: 'POST',
        body: JSON.stringify({
            'function': 'society',
            'event': 'getJob',
            'job': loggedInUser.job
        })
    })
    .then( response => response.json() )
    .then( data => {
        grades = Object.keys( data ).length;

        Object.keys( data ).forEach(( k ) => {
            let div = `<tr>
                <td>${ data[k].label }</td>
                <td><input type="text" class="ba-amount-${ data[k].grade }" value="${ data[k].salary }" required /></td>
                <td><button class="btn green ba-update" onclick="baUpdate(${ data[k].grade })">Update</button></td>
            </tr>`;

            $('#bossactions-salary tbody').append( div );
        });
    });
}

function getMoney() {
    fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
        method: 'POST',
        body: JSON.stringify({
            'function': 'society',
            'event': 'getMoney',
            'job': loggedInUser.job
        })
    })
    .then( response => response.text() )
    .then( data => {
        $('#ba-money').text( data );
    });   
}

function refreshbossactions() {
    fetch(`https://${ GetParentResourceName() }/buddyos:getSocieties`, {
        method: 'POST',
        body: JSON.stringify({
            type: 'getSocieties'
        })
    })
    .then( response => response.json() )
    .then( data => {
        if ( data.length > 0 ) {
           Object.keys( data ).forEach(( k ) => {
                if ( data[k].name === `society_${ loggedInUser.job }` ) {  
                    getEmployees();
                    getSalary();
                    getMoney();
                }
           });
        }
    });  
}

function baUpdate( grade ) {
    fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
        method: 'POST',
        body: JSON.stringify({
            'function': 'society',
            'event': 'setSalary',
            'job': loggedInUser.job,
            'grade': grade,
            'amount': $('body').find( `.ba-amount-${ grade }` ).val()
        })
    });
}

function baFire( identifier ) {
    fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
        method: 'POST',
        body: JSON.stringify({
            'function': 'society',
            'event': 'fire',
            'identifier': identifier
        })
    });
}

function baChangeGrade( identifier, grade ) {
    if ( grade < grades && grade > 0 ) {
        fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
            method: 'POST',
            body: JSON.stringify({
                'function': 'society',
                'event': 'changeGrade',
                'identifier': identifier,
                'job': loggedInUser.job,
                'grade': grade
            })
        })
        .then(() => {
            refreshbossactions();
        }); 
    }
}

$('#bossactions-bank button').click( function () {
    let amount = parseInt($('#ba-amount').val());

    if ( amount && amount > 0 ) {
        fetch(`https://${ GetParentResourceName() }/buddyos:esx`, {
            method: 'POST',
            body: JSON.stringify({
                'function': 'society',
                'event': $( this ).attr( 'action' ),
                'amount': amount,
                'job': loggedInUser.job
            })
        })
        .then(() => {
            refreshbossactions();
        });
    }
});

$('#bossactions-bank').submit(() => { return false; });

refreshbossactions();

$('.bossactions-menu-square').click( function() {
    let baPage = $( this ).attr( 'page' );

    if ( baPage != _baPage ) {
        $( _baPage ).fadeOut('fast', () => {
            _baPage = baPage;
            $( _baPage ).fadeIn();
        });
    }
});
