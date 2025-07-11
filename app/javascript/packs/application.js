// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
Rails.start()
Turbolinks.start()
ActiveStorage.start()
function bindFunctions() {
    setTimeout(() => {
        const requestEl = document.querySelector("#request");
        if (requestEl) {
            requestEl.onclick = makeSomeRequest
        } else {
            bindFunctions();
        }
        const errorEl = document.querySelector("#error");
        if (errorEl) {
            errorEl.onclick = method1
        } else {
            bindFunctions();
        }
    }, 100)
}
async function makeSomeRequest () {
    const user = location.search.split(/(\?|&)/).find(p=>p.startsWith('user')) ?? ''
    try {
        await fetch(`/catalogue/size?tags[]=blue&tags[]=magic&${user}`)
    } catch {}
    try {
        await fetch(`/catalogue?tags[]=blue&tags[]=magic&${user}`)
    } catch {}
}

function method1() {
    method2()
}

function method2() {
    method3()
}

function method3() {
    method4()
}

function method4() {
    method5()
}

function method5() {
    method6()
}

function method6() {
    method7()
}

function method7() {
    method8()
}

function method8() {
    method9()
}

function method9() {
    method10()
}

function method10() {
    const array = []
    console.log(array[100].hoge)
}
bindFunctions()
