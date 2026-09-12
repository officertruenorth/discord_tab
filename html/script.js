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
        const roles = (player.roles || [])
            .map((role) => `<span class="role-pill" style="--role-color:${role.color || '#64748b'}"><span>${role.icon || '•'}</span>${role.label || role.acePermission}</span>`)
            .join('');

        tr.innerHTML = `
            <td>${player.id}</td>
            <td>${player.name}</td>
            <td>${player.discordName}</td>
            <td>${player.ping}</td>
            <td>${roles ? `<div class="role-list">${roles}</div>` : '<span class="empty">None</span>'}</td>
        `;

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
        titleEl.textContent = payload.title || titleEl.textContent;
        subtitleEl.textContent = payload.subtitle || subtitleEl.textContent;
        players = payload.players || [];
        render();
    }
});

document.querySelectorAll('th[data-sort]').forEach((header) => {
    header.addEventListener('click', () => {
        const nextSort = header.dataset.sort;

        if (sortBy === nextSort) {
            sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            sortBy = nextSort;
            sortDirection = 'asc';
        }

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
