<template>
<div id="app">
  <div id="nav">
    <router-link to="/">Match DMC colors</router-link> |
    <router-link to="/about">About</router-link>
  </div>
  <router-view />
</div>
</template>

<style lang="scss">
@import "~@/assets/scss/vendors/bootstrap-vue/index";
$primary-color: #2A97B3;
#app {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
}

.primary-color {
  color: $primary-color;
}

#nav {
    padding: 0.75rem 2rem;

    background: $primary-color;

    a {
        font-weight: bold;
        color: #222;

        &.router-link-exact-active {
            color: #ffffff;
            text-decoration: none;
        }
    }
}
</style>
