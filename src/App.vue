<template>
<div id="app" class="d-flex flex-column justify-content-between min-vh-100">
  <header id="nav" class="d-flex justify-content-between">
    <router-link to="/">Match DMC colors</router-link>
    <router-link to="/about">About</router-link>
  </header>
  <router-view />
  <footer class="d-flex justify-content-between border-top py-3 px-3">
    <span class="fa-sm">&copy; {{year}} Laura D. Hughes</span>
    <div>
    <a href="https://github.com/flaneuse/image2dmc" target="_blank"><b-icon class="ml-4" font-scale="1.5" icon="github" variant="secondary"></b-icon></a>
    <a href="https://twitter.com/flaneuseks" target="_blank"><b-icon class="ml-4" font-scale="1.5" icon="twitter" variant="secondary"></b-icon></a>
    </div>

  </footer>
</div>
</template>

<script>
// @ is an alias to /src
import ImportPic from '@/components/ImportPic.vue'

export default {
  name: 'image2DMC',
  data() {
    return {
      year: null
    }
  },
  mounted() {
    this.year = new Date().getFullYear();
  }
}
</script>


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
        color: #dbf3f3;

        &.router-link-exact-active {}
    }
}


.fa-sm {
    font-size: 0.85rem;
}
</style>
