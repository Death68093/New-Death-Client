(function() {
    const menu = document.createElement('div');
    menu.style.position = 'fixed';
    menu.style.top = '10px';
    menu.style.right = '10px';
    menu.style.backgroundColor = 'white';
    menu.style.border = '1px solid black';
    menu.style.padding = '10px';
    menu.style.zIndex = 10000;
    document.body.appendChild(menu);
    menu.innerHTML = `
        <button id="getLinksBtn">Get Links</button>
        <button id="closeMenuBtn">Close</button>
        <button id="findTextBtn">Find Text</button>
        <ul id="linksOutput" style="margin-top:10px; max-height:200px; overflow:auto;"></ul>
    `;

    document.getElementById('getLinksBtn').onclick = function() {
        const links = Array.from(document.querySelectorAll('a')).map(a => a.href);
        const outputUl = document.getElementById('linksOutput');
        outputUl.innerHTML = '';
        links.forEach(link => {
            const li = document.createElement('li');
            li.innerHTML = `<a href="${link}" target="_blank">${link}</a>`;
            outputUl.appendChild(li);
        });
    };

    function highlightText(node, searchText) {
        if (node.nodeType === Node.TEXT_NODE) {
            const regex = new RegExp(searchText, 'gi');
            const frag = document.createDocumentFragment();
            let lastIndex = 0;
            let match;
            while ((match = regex.exec(node.data)) !== null) {
                if (match.index > lastIndex) {
                    frag.appendChild(document.createTextNode(node.data.slice(lastIndex, match.index)));
                }
                const span = document.createElement('span');
                span.style.backgroundColor = 'yellow';
                span.textContent = match[0];
                frag.appendChild(span);
                lastIndex = match.index + match[0].length;
            }
            if (lastIndex < node.data.length) {
                frag.appendChild(document.createTextNode(node.data.slice(lastIndex)));
            }
            node.parentNode.replaceChild(frag, node);
        } else if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== 'SCRIPT' && node.tagName !== 'STYLE') {
            Array.from(node.childNodes).forEach(child => highlightText(child, searchText));
        }
    }

    document.getElementById('findTextBtn').onclick = function() {
        const searchText = prompt('Enter text to find:');
        if (!searchText) return;

        highlightText(document.body, searchText);

        const outputUl = document.getElementById('linksOutput');
        const li = document.createElement('li');
        li.textContent = `Highlighted all occurrences of "${searchText}"`;
        outputUl.innerHTML = '';
        outputUl.appendChild(li);
    };

    document.getElementById('closeMenuBtn').onclick = function() {
        document.body.removeChild(menu);
    };
})();
