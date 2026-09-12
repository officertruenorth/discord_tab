const app = document.getElementById('app');
const rowsEl = document.getElementById('rows');
const titleEl = document.getElementById('title');
const subtitleEl = document.getElementById('subtitle');
const playerCountEl = document.getElementById('playerCount');

let players = [];
let sortBy = 'id';
let sortDirection = 'asc';

const roleText = (roles) => (roles || []).map((role) => role.label).join(', ');

const compare = (a, b) => {
    if (sortBy === 'ping' || sortBy === 'id') {
        return (Number(a[sortBy]) || 0) - (Number(b[sortBy]) || 0);
    }

    if (sortBy === 'roles') {
        return roleText(a.roles).localeCompare(roleText(b.roles));
    }

    return String(a[sortBy] || '').localeCompare(String(b[sortBy] || ''), undefined, { sensitivity: 'base' });
};

const sortedPlayers = () => {
    const data = [...players].sort((a, b) => {
        const value = compare(a, b);
        return sortDirection === 'asc' ? value : -value;
    });

    return data;
};

const render = () => {
    const data = sortedPlayers();
    rowsEl.innerHTML = '';

    for (const player of data) {
        const tr = document.createElement('tr');
        const idTd = document.createElement('td');
        idTd.textContent = String(player.id ?? '');

        const nameTd = document.createElement('td');
        nameTd.textContent = String(player.name ?? '');

        const discordTd = document.createElement('td');
        discordTd.textContent = String(player.discordName ?? '');

        const pingTd = document.createElement('td');
        pingTd.textContent = String(player.ping ?? '');

        const rolesTd = document.createElement('td');
        const playerRoles = player.roles || [];

        if (playerRoles.length) {
            const roleList = document.createElement('div');
            roleList.className = 'role-list';

            for (const role of playerRoles) {
                const rolePill = document.createElement('span');
                rolePill.className = 'role-pill';
                rolePill.style.setProperty('--role-color', role.color || '#64748b');

                const icon = document.createElement('span');
                icon.textContent = role.icon || '•';

                const label = document.createElement('span');
                label.textContent = role.label || role.acePermission || 'Role';

                rolePill.appendChild(icon);
                rolePill.appendChild(label);
                roleList.appendChild(rolePill);
            }

            rolesTd.appendChild(roleList);
        } else {
            const empty = document.createElement('span');
            empty.className = 'empty';
            empty.textContent = 'None';
            rolesTd.appendChild(empty);
        }

        tr.appendChild(idTd);
        tr.appendChild(nameTd);
        tr.appendChild(discordTd);
        tr.appendChild(pingTd);
        tr.appendChild(rolesTd);

        rowsEl.appendChild(tr);
    }

    playerCountEl.textContent = `${data.length} Player${data.length === 1 ? '' : 's'}`;
};

const setVisible = (visible) => {
    app.classList.toggle('hidden', !visible);
};

window.addEventListener('message', (event) => {
    const message = event.data || {};

    if (message.type === 'open') {
        setVisible(true);
        return;
    }

    if (message.type === 'close') {
        setVisible(false);
        return;
    }

    if (message.type === 'update') {
        const payload = message.payload || {};
        if (payload.title !== undefined) {
            titleEl.textContent = payload.title;
        }
        if (payload.subtitle !== undefined) {
            subtitleEl.textContent = payload.subtitle;
        }
        players = payload.players || [];
        render();
    }
});

document.querySelectorAll('.sort-button[data-sort]').forEach((header) => {
    header.addEventListener('click', () => {
        const nextSort = header.dataset.sort;

        if (sortBy === nextSort) {
            sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            sortBy = nextSort;
            sortDirection = 'asc';
        }

        document.querySelectorAll('.sort-button[data-sort]').forEach((button) => {
            const header = button.closest('th');
            if (!header) {
                return;
            }

            if (button.dataset.sort === sortBy) {
                header.setAttribute('aria-sort', sortDirection === 'asc' ? 'ascending' : 'descending');
            } else {
                header.setAttribute('aria-sort', 'none');
            }
        });

        render();
    });
});

document.addEventListener('keyup', (event) => {
    if (event.key !== 'Escape') {
        return;
    }

    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify({})
    });
});
